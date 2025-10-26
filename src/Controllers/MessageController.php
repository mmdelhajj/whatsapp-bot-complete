<?php
/**
 * Message Controller
 * Handles incoming messages and orchestrates responses
 */

class MessageController {
    private $customerModel;
    private $messageModel;
    private $productModel;
    private $orderModel;
    private $claudeAI;
    private $proxSMS;
    private $brainsAPI;

    public function __construct() {
        $this->customerModel = new Customer();
        $this->messageModel = new Message();
        $this->productModel = new Product();
        $this->orderModel = new Order();
        $this->claudeAI = new ClaudeAI();
        $this->proxSMS = new ProxSMSService();
        $this->brainsAPI = new BrainsAPI();
    }

    /**
     * Main message processing entry point
     */
    public function processIncomingMessage($phone, $message) {
        try {
            // Log incoming message
            logMessage("Incoming message from {$phone}: {$message}", 'INFO', WEBHOOK_LOG_FILE);

            // Find or create customer
            $customer = $this->customerModel->findOrCreateByPhone($phone);

            // Save incoming message
            $this->messageModel->saveReceived($customer['id'], $message);

            // Try to link customer with Brains account if not linked
            if (empty($customer['brains_account_code'])) {
                $this->tryLinkBrainsAccount($customer['id'], $phone);
                // Refresh customer data
                $customer = $this->customerModel->findById($customer['id']);
            }

            // Process message based on intent
            $response = $this->generateResponse($customer, $message);

            // Send response
            if ($response) {
                $sendResult = $this->proxSMS->sendMessage($phone, $response);

                if ($sendResult['success']) {
                    // Save sent message
                    $this->messageModel->saveSent($customer['id'], $response);
                    logMessage("Response sent to {$phone}", 'INFO', WEBHOOK_LOG_FILE);
                } else {
                    logMessage("Failed to send response: " . ($sendResult['error'] ?? 'Unknown'), 'ERROR', WEBHOOK_LOG_FILE);
                }
            }

            return [
                'success' => true,
                'customer_id' => $customer['id']
            ];

        } catch (Exception $e) {
            logMessage("Error processing message: " . $e->getMessage(), 'ERROR', WEBHOOK_LOG_FILE);

            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Generate appropriate response based on message content
     */
    private function generateResponse($customer, $message) {
        $messageLower = mb_strtolower($message, 'UTF-8');

        // Check for specific intents first
        // 1. Product search
        if ($this->isProductSearch($messageLower)) {
            return $this->handleProductSearch($customer, $message);
        }

        // 2. Balance inquiry
        if ($this->isBalanceInquiry($messageLower)) {
            return $this->handleBalanceInquiry($customer);
        }

        // 3. Order placement
        if ($this->isOrderIntent($messageLower)) {
            return $this->handleOrderIntent($customer, $message);
        }

        // 4. Help request
        if ($this->isHelpRequest($messageLower)) {
            return $this->getHelpMessage();
        }

        // 5. Greeting
        if ($this->isGreeting($messageLower)) {
            return $this->getWelcomeMessage($customer);
        }

        // Default: Use AI for complex queries
        return $this->handleWithAI($customer, $message);
    }

    /**
     * Handle product search
     */
    private function handleProductSearch($customer, $message) {
        // Extract search query
        $searchQuery = $this->extractSearchQuery($message);

        if (!$searchQuery) {
            return "🔍 ما هو المنتج الذي تبحث عنه؟\n\nيمكنك البحث باسم الكتاب أو الكود.";
        }

        // Search products
        $products = $this->productModel->search($searchQuery, 5);

        if (empty($products)) {
            return "❌ عذراً، لم أجد منتجات مطابقة لـ \"$searchQuery\".\n\nجرّب كلمات بحث مختلفة أو اتصل بنا للمساعدة.";
        }

        // Format results
        return $this->claudeAI->formatProductResults($products);
    }

    /**
     * Handle balance inquiry
     */
    private function handleBalanceInquiry($customer) {
        if (empty($customer['brains_account_code'])) {
            return "💳 عذراً، حسابك غير مرتبط بنظامنا بعد.\n\nالرجاء التواصل معنا لربط حسابك.";
        }

        $balance = $customer['balance'] ?? 0;
        $creditLimit = $customer['credit_limit'] ?? 0;
        $available = $creditLimit - abs($balance);

        $message = "💳 معلومات حسابك:\n\n";
        $message .= "👤 الاسم: {$customer['name']}\n";
        $message .= "💰 الرصيد: " . number_format($balance, 0, '.', ',') . " " . CURRENCY . "\n";
        $message .= "📊 الحد الائتماني: " . number_format($creditLimit, 0, '.', ',') . " " . CURRENCY . "\n";
        $message .= "✅ المتاح: " . number_format($available, 0, '.', ',') . " " . CURRENCY . "\n";

        return $message;
    }

    /**
     * Handle order intent
     */
    private function handleOrderIntent($customer, $message) {
        // Extract product code or name from message
        $productCode = $this->extractProductCode($message);

        if (!$productCode) {
            return "🛒 لإنشاء طلب، الرجاء تحديد:\n\n1. اسم المنتج أو الكود\n2. الكمية المطلوبة\n\nمثال: \"بدي كتاب رياضيات 2 حبة\"";
        }

        $product = $this->productModel->findByCode($productCode);

        if (!$product) {
            return "❌ عذراً، المنتج غير موجود.\n\nالرجاء البحث عن المنتج أولاً للحصول على الكود الصحيح.";
        }

        if ($product['stock_quantity'] <= 0) {
            return "📦 عذراً، المنتج \"{$product['item_name']}\" غير متوفر حالياً.\n\nهل تريد طلب منتج آخر؟";
        }

        // Extract quantity (default 1)
        $quantity = $this->extractQuantity($message);

        // Create order
        try {
            $order = $this->orderModel->create($customer['id'], [
                [
                    'product_sku' => $product['item_code'],
                    'product_name' => $product['item_name'],
                    'quantity' => $quantity,
                    'unit_price' => $product['price']
                ]
            ], 'Created via WhatsApp');

            // Try to create in Brains
            $this->tryCreateBrainsInvoice($order, $customer);

            // Send confirmation
            $this->proxSMS->sendOrderConfirmation($customer['phone'], $order);

            return null; // Already sent via sendOrderConfirmation

        } catch (Exception $e) {
            logMessage("Order creation failed: " . $e->getMessage(), 'ERROR');
            return "⚠️ حدث خطأ أثناء إنشاء الطلب.\n\nالرجاء المحاولة مرة أخرى أو الاتصال بنا.";
        }
    }

    /**
     * Handle with AI (Claude)
     */
    private function handleWithAI($customer, $message) {
        $result = $this->claudeAI->processMessage(
            $customer['id'],
            $message,
            $customer
        );

        if ($result['success']) {
            return $result['message'];
        } else {
            return "🤖 عذراً، أواجه مشكلة في المعالجة.\n\nكيف يمكنني مساعدتك؟";
        }
    }

    /**
     * Try to link customer with Brains account
     */
    private function tryLinkBrainsAccount($customerId, $phone) {
        try {
            $account = $this->brainsAPI->findAccountByPhone($phone);

            if ($account) {
                $this->customerModel->linkBrainsAccount($customerId, $account);
                logMessage("Customer {$customerId} linked to Brains account {$account['AccoCode']}", 'INFO');
            }
        } catch (Exception $e) {
            logMessage("Failed to link Brains account: " . $e->getMessage(), 'WARNING');
        }
    }

    /**
     * Try to create invoice in Brains
     */
    private function tryCreateBrainsInvoice($order, $customer) {
        if (empty($customer['brains_account_code'])) {
            return false;
        }

        try {
            $items = [];
            foreach ($order['items'] as $item) {
                $items[] = [
                    'ItemCode' => $item['product_sku'],
                    'Quantity' => $item['quantity'],
                    'UnitPrice' => $item['unit_price']
                ];
            }

            $result = $this->brainsAPI->createSale([
                'customer_code' => $customer['brains_account_code'],
                'invoice_date' => date('Y-m-d'),
                'items' => $items,
                'notes' => "WhatsApp Order: {$order['order_number']}"
            ]);

            if ($result && isset($result['InvoiceNo'])) {
                $this->orderModel->linkBrainsInvoice($order['id'], $result['InvoiceNo']);
                return true;
            }

        } catch (Exception $e) {
            logMessage("Failed to create Brains invoice: " . $e->getMessage(), 'ERROR');
        }

        return false;
    }

    // Intent detection helpers
    private function isProductSearch($message) {
        return preg_match('/(بحث|كتاب|search|find|ابحث|دور|عندك|موجود)/u', $message);
    }

    private function isBalanceInquiry($message) {
        return preg_match('/(رصيد|حساب|balance|account|كم علي|ديون)/u', $message);
    }

    private function isOrderIntent($message) {
        return preg_match('/(طلب|order|بدي|اطلب|شراء|buy)/u', $message);
    }

    private function isHelpRequest($message) {
        return preg_match('/(مساعدة|help|ساعد|كيف)/u', $message);
    }

    private function isGreeting($message) {
        return preg_match('/(مرحبا|hello|hi|هلا|السلام|صباح|مساء)/u', $message);
    }

    // Extraction helpers
    private function extractSearchQuery($message) {
        // Remove common words
        $cleaned = preg_replace('/(بحث عن|ابحث عن|بدي|عندك|موجود)/u', '', $message);
        return trim($cleaned);
    }

    private function extractProductCode($message) {
        // Look for product code pattern (e.g., BK-2024-001)
        if (preg_match('/([A-Z]{2,}-\d{4,}-\d{3,})/i', $message, $matches)) {
            return $matches[1];
        }
        return null;
    }

    private function extractQuantity($message) {
        // Look for numbers in Arabic or English
        if (preg_match('/(\d+|واحد|اثنين|ثلاثة|أربعة|خمسة)/u', $message, $matches)) {
            $arabicNumbers = [
                'واحد' => 1, 'اثنين' => 2, 'ثلاثة' => 3,
                'أربعة' => 4, 'خمسة' => 5
            ];

            return $arabicNumbers[$matches[1]] ?? (int)$matches[1];
        }

        return 1; // Default
    }

    private function getWelcomeMessage($customer) {
        $name = $customer['name'] ?? null;
        $greeting = $name ? "مرحباً {$name}!" : "مرحباً!";

        return "{$greeting} 👋\n\n" .
               "أهلاً بك في **" . STORE_NAME . "** 📚\n\n" .
               "كيف يمكنني مساعدتك اليوم؟\n\n" .
               "• البحث عن كتب 🔍\n" .
               "• الاستفسار عن الأسعار 💰\n" .
               "• طلب منتجات 🛒\n" .
               "• الاستعلام عن حسابك 💳";
    }

    private function getHelpMessage() {
        return "📚 **كيف يمكنني مساعدتك؟**\n\n" .
               "**للبحث عن كتاب:**\n" .
               "اكتب: \"بحث عن [اسم الكتاب]\"\n\n" .
               "**لطلب منتج:**\n" .
               "اكتب: \"بدي [اسم المنتج]\"\n\n" .
               "**للاستعلام عن حسابك:**\n" .
               "اكتب: \"رصيدي\" أو \"حسابي\"\n\n" .
               "**للتواصل:**\n" .
               "يمكنك الاتصال بنا مباشرة أو زيارة متجرنا في " . STORE_LOCATION;
    }
}
