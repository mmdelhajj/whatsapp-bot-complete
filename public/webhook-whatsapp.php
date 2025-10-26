<?php
/**
 * WhatsApp Webhook Endpoint
 * Receives incoming messages from ProxSMS
 */

// Load configuration
require_once dirname(__DIR__) . '/config/config.php';

// Set headers
header('Content-Type: application/json');

// Log raw input
$rawInput = file_get_contents('php://input');
logMessage("Webhook received: " . $rawInput, 'DEBUG', WEBHOOK_LOG_FILE);

try {
    // Parse JSON input
    $input = json_decode($rawInput, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        logMessage("Invalid JSON: " . json_last_error_msg(), 'ERROR', WEBHOOK_LOG_FILE);
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON']);
        exit;
    }

    // Validate webhook secret (if configured)
    if (defined('WHATSAPP_WEBHOOK_SECRET') && !empty(WHATSAPP_WEBHOOK_SECRET)) {
        $providedSecret = $_SERVER['HTTP_X_WEBHOOK_SECRET'] ?? ($input['secret'] ?? '');

        if ($providedSecret !== WHATSAPP_WEBHOOK_SECRET) {
            logMessage("Invalid webhook secret", 'WARNING', WEBHOOK_LOG_FILE);
            http_response_code(403);
            echo json_encode(['error' => 'Forbidden']);
            exit;
        }
    }

    // Extract message data
    $phone = $input['phone'] ?? $input['from'] ?? null;
    $message = $input['message'] ?? $input['text'] ?? null;
    $messageType = $input['type'] ?? 'text';

    // Validate required fields
    if (!$phone || !$message) {
        logMessage("Missing required fields: phone or message", 'ERROR', WEBHOOK_LOG_FILE);
        http_response_code(400);
        echo json_encode(['error' => 'Missing required fields']);
        exit;
    }

    // Process only text messages (ignore media for now)
    if ($messageType !== 'text') {
        logMessage("Ignoring non-text message type: {$messageType}", 'INFO', WEBHOOK_LOG_FILE);
        http_response_code(200);
        echo json_encode(['status' => 'ignored', 'reason' => 'non-text message']);
        exit;
    }

    // Process the message
    $controller = new MessageController();
    $result = $controller->processIncomingMessage($phone, $message);

    if ($result['success']) {
        logMessage("Message processed successfully for customer {$result['customer_id']}", 'INFO', WEBHOOK_LOG_FILE);
        http_response_code(200);
        echo json_encode([
            'status' => 'success',
            'customer_id' => $result['customer_id']
        ]);
    } else {
        logMessage("Message processing failed: " . ($result['error'] ?? 'Unknown error'), 'ERROR', WEBHOOK_LOG_FILE);
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'error' => $result['error'] ?? 'Processing failed'
        ]);
    }

} catch (Exception $e) {
    logMessage("Webhook exception: " . $e->getMessage(), 'ERROR', WEBHOOK_LOG_FILE);
    logMessage("Stack trace: " . $e->getTraceAsString(), 'ERROR', WEBHOOK_LOG_FILE);

    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'error' => 'Internal server error'
    ]);
}
