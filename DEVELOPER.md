# Developer Documentation - WhatsApp Bot v4.0

Technical documentation for developers.

---

## 🏗️ Architecture

### Technology Stack
- **Backend:** PHP 8.2
- **Database:** MySQL 8.0
- **Web Server:** Nginx
- **Cache:** Redis
- **AI:** Anthropic Claude Sonnet 4.5
- **WhatsApp:** ProxSMS API

### Directory Structure
```
whatsapp-bot-complete/
├── admin/                  # Admin dashboard
│   ├── pages/             # Admin pages
│   ├── assets/            # CSS, JS, images
│   ├── index.php          # Main dashboard
│   └── test-apis.php      # API testing page
├── config/                # Configuration files
│   ├── config.php         # Main configuration
│   ├── Database.php       # Database connection
│   └── schema.sql         # Database schema
├── public/                # Public web root
│   ├── index.php          # Landing page
│   └── webhook-whatsapp.php  # WhatsApp webhook
├── src/                   # Application source
│   ├── Controllers/       # Business logic controllers
│   │   └── MessageController.php
│   ├── Models/            # Data models
│   │   ├── Customer.php
│   │   ├── Message.php
│   │   ├── Order.php
│   │   └── Product.php
│   └── Services/          # External integrations
│       ├── BrainsAPI.php
│       ├── ClaudeAI.php
│       └── ProxSMSService.php
├── scripts/               # CLI scripts
│   └── sync_from_brains.php
├── logs/                  # Application logs
├── .env.example           # Environment template
├── install.sh             # Installation script
└── README.md             # Main documentation
```

---

## 📚 Core Components

### 1. Database Layer (`config/Database.php`)

**Singleton pattern for database connections**

```php
$db = Database::getInstance();

// Fetch single row
$customer = $db->fetchOne("SELECT * FROM customers WHERE id = ?", [123]);

// Fetch multiple rows
$customers = $db->fetchAll("SELECT * FROM customers LIMIT 10");

// Insert
$id = $db->insert('customers', [
    'phone' => '+9613123456',
    'name' => 'John Doe'
]);

// Update
$db->update('customers',
    ['name' => 'Jane Doe'],
    'id = :id',
    ['id' => 123]
);
```

### 2. Models

#### Customer Model (`src/Models/Customer.php`)
```php
$customerModel = new Customer();

// Find or create by phone
$customer = $customerModel->findOrCreateByPhone('+9613123456');

// Link to Brains account
$customerModel->linkBrainsAccount($customerId, $brainsAccountData);

// Get with message history
$customer = $customerModel->getWithMessages($customerId, 10);
```

#### Product Model (`src/Models/Product.php`)
```php
$productModel = new Product();

// Search products
$products = $productModel->search('رياضيات', 10);

// Bulk upsert (for sync)
$result = $productModel->bulkUpsert($brainsProducts);
```

#### Order Model (`src/Models/Order.php`)
```php
$orderModel = new Order();

// Create order
$order = $orderModel->create($customerId, [
    [
        'product_sku' => 'BK-001',
        'product_name' => 'Math Book',
        'quantity' => 2,
        'unit_price' => 50000
    ]
]);

// Update status
$orderModel->updateStatus($orderId, 'confirmed');
```

### 3. Services

#### Brains API Service (`src/Services/BrainsAPI.php`)
```php
$brainsAPI = new BrainsAPI();

// Fetch items
$items = $brainsAPI->fetchItems();

// Fetch accounts
$accounts = $brainsAPI->fetchAccounts();

// Create sale
$result = $brainsAPI->createSale([
    'customer_code' => 'C-12345',
    'invoice_date' => '2024-10-26',
    'items' => [...]
]);

// Sync products
$result = $brainsAPI->syncProducts();
```

#### Claude AI Service (`src/Services/ClaudeAI.php`)
```php
$claudeAI = new ClaudeAI();

// Process message
$result = $claudeAI->processMessage(
    $customerId,
    "بدي كتاب رياضيات",
    $customerData
);

// Format product results
$message = $claudeAI->formatProductResults($products);
```

#### ProxSMS Service (`src/Services/ProxSMSService.php`)
```php
$proxSMS = new ProxSMSService();

// Send text message
$result = $proxSMS->sendMessage('+9613123456', 'Hello!');

// Send order confirmation
$proxSMS->sendOrderConfirmation($phone, $order);

// Send welcome message
$proxSMS->sendWelcome($phone, $customerName);
```

### 4. Message Controller

Main business logic for processing messages:

```php
$controller = new MessageController();

$result = $controller->processIncomingMessage($phone, $message);
```

**Processing flow:**
1. Find/create customer
2. Save incoming message
3. Try to link Brains account
4. Detect intent (product search, order, balance, etc.)
5. Generate response
6. Send via ProxSMS
7. Save sent message

---

## 🔌 API Integrations

### Brains ERP API

**Items Endpoint:**
```
GET http://194.126.6.162:1980/Api/items

Response:
[
  {
    "ItemCode": "BK-2024-001",
    "ItemName": "كتاب الرياضيات",
    "Price": 45000.00,
    "StockQty": 150,
    "Category": "School Books"
  }
]
```

**Accounts Endpoint:**
```
GET http://194.126.6.162:1980/Api/accounts?type=1&accocode=41110

Response:
[
  {
    "AccoCode": "C-12345",
    "AccoName": "أحمد محمد",
    "Phone": "+9613123456",
    "Balance": 125000.00,
    "CreditLimit": 500000.00
  }
]
```

**Sales Endpoint:**
```
POST http://194.126.6.162:1980/Api/sales

Body:
{
  "CustomerCode": "C-12345",
  "InvoiceDate": "2024-10-26",
  "Items": [
    {
      "ItemCode": "BK-2024-001",
      "Quantity": 2,
      "UnitPrice": 45000.00
    }
  ]
}
```

### ProxSMS API

**Send Message:**
```
POST https://api.proxsms.com/message/send

Body:
{
  "secret": "YOUR_SECRET",
  "account": "YOUR_ACCOUNT_ID",
  "recipient": "+9613123456",
  "type": "text",
  "message": "Hello!"
}
```

### Anthropic Claude API

**Send Message:**
```
POST https://api.anthropic.com/v1/messages

Headers:
  x-api-key: YOUR_API_KEY
  anthropic-version: 2023-06-01

Body:
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "messages": [
    {"role": "user", "content": "Hello"}
  ]
}
```

---

## 🗄️ Database Schema

### Core Tables

**customers**
- `id` - Primary key
- `phone` - Unique phone number
- `name` - Customer name
- `brains_account_code` - Link to Brains
- `balance` - Account balance
- `credit_limit` - Credit limit

**messages**
- `id` - Primary key
- `customer_id` - Foreign key
- `direction` - RECEIVED/SENT
- `message` - Message content
- `created_at` - Timestamp

**product_info**
- `id` - Primary key
- `item_code` - Unique product code
- `item_name` - Product name
- `price` - Product price
- `stock_quantity` - Stock level

**orders**
- `id` - Primary key
- `customer_id` - Foreign key
- `order_number` - Unique order number
- `status` - Order status
- `total_amount` - Total amount
- `brains_invoice_id` - Link to Brains invoice

---

## 🔄 Webhook Flow

```
ProxSMS → webhook-whatsapp.php → MessageController
                                         ↓
                            [Process Message Logic]
                                         ↓
                         ┌───────────────┴───────────────┐
                         ↓                               ↓
                  [Search Product]              [Check Balance]
                  [Create Order]                [AI Response]
                         ↓                               ↓
                         └───────────────┬───────────────┘
                                         ↓
                              [Send Response via ProxSMS]
```

---

## 🧪 Testing

### Test API Connections
```bash
# Via admin dashboard
http://your-domain/admin/test-apis.php

# Or via command line
php -r "
require 'config/config.php';
\$api = new BrainsAPI();
print_r(\$api->testConnection());
"
```

### Test Webhook Locally
```bash
curl -X POST http://localhost/webhook-whatsapp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+9613123456",
    "message": "مرحبا"
  }'
```

### Test Sync Script
```bash
php /var/www/whatsapp-bot/scripts/sync_from_brains.php
```

---

## 🛠️ Development Tips

### Enable Debug Mode
Edit `config/config.php`:
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

### Custom Logging
```php
logMessage("Debug info", 'DEBUG', LOG_FILE);
logMessage("Error occurred", 'ERROR', LOG_FILE);
```

### Database Queries
```php
// Enable query logging
$db->query("SET global log_output = 'FILE'");
$db->query("SET global general_log_file='/tmp/mysql.log'");
$db->query("SET global general_log = 1");
```

---

## 📝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

---

## 📄 License

MIT License - See LICENSE file

---

**Made with ❤️ in Lebanon 🇱🇧**
