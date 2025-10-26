<?php
/**
 * Main Configuration File
 * Loads environment variables and defines constants
 */

// Load environment variables
function loadEnv() {
    static $env = null;

    if ($env !== null) {
        return $env;
    }

    $envFile = dirname(__DIR__) . '/.env';
    if (!file_exists($envFile)) {
        die("ERROR: .env file not found");
    }

    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $env = [];

    foreach ($lines as $line) {
        if (strpos($line, '#') === 0) continue;
        if (strpos($line, '=') === false) continue;

        list($key, $value) = explode('=', $line, 2);
        $env[trim($key)] = trim($value);
    }

    return $env;
}

// Get environment variable
function env($key, $default = null) {
    $env = loadEnv();
    return isset($env[$key]) ? $env[$key] : $default;
}

// Define constants
define('APP_ROOT', dirname(__DIR__));
define('LOG_FILE', APP_ROOT . '/logs/app.log');
define('WEBHOOK_LOG_FILE', APP_ROOT . '/logs/webhook.log');

// Brains API Configuration
define('BRAINS_API_BASE', env('BRAINS_API_BASE', 'http://194.126.6.162:1980/Api'));
define('BRAINS_ITEMS_ENDPOINT', BRAINS_API_BASE . '/items');
define('BRAINS_ACCOUNTS_ENDPOINT', BRAINS_API_BASE . '/accounts');
define('BRAINS_SALES_ENDPOINT', BRAINS_API_BASE . '/sales');

// WhatsApp (ProxSMS) Configuration
define('WHATSAPP_API_URL', 'https://api.proxsms.com/message/send');
define('WHATSAPP_ACCOUNT_ID', env('WHATSAPP_ACCOUNT_ID'));
define('WHATSAPP_SEND_SECRET', env('WHATSAPP_SEND_SECRET'));
define('WHATSAPP_WEBHOOK_SECRET', env('WEBHOOK_SECRET', ''));

// Anthropic Claude Configuration
define('ANTHROPIC_API_KEY', env('ANTHROPIC_API_KEY'));
define('ANTHROPIC_API_URL', 'https://api.anthropic.com/v1/messages');
define('ANTHROPIC_MODEL', 'claude-sonnet-4-20250514');
define('ANTHROPIC_MAX_TOKENS', 1024);

// Database Configuration
define('DB_HOST', env('DB_HOST', 'localhost'));
define('DB_NAME', env('DB_NAME', 'whatsapp_bot'));
define('DB_USER', env('DB_USER', 'whatsapp_user'));
define('DB_PASS', env('DB_PASS', ''));

// Application Settings
define('TIMEZONE', 'Asia/Beirut');
define('CURRENCY', 'LBP');
define('STORE_NAME', 'Librarie Memoires');
define('STORE_LOCATION', 'Tripoli, Lebanon');

// Sync Settings
define('SYNC_INTERVAL_HOURS', 4);
define('API_TIMEOUT_SECONDS', 30);
define('API_RETRY_ATTEMPTS', 3);

// Session Settings
define('SESSION_LIFETIME', 3600); // 1 hour

// Set timezone
date_default_timezone_set(TIMEZONE);

// Error reporting
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', LOG_FILE);

// Logging function
function logMessage($message, $level = 'INFO', $logFile = LOG_FILE) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[{$timestamp}] [{$level}] {$message}\n";
    file_put_contents($logFile, $logEntry, FILE_APPEND);
}

// JSON response helper
function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

// Autoloader
spl_autoload_register(function ($class) {
    $paths = [
        APP_ROOT . '/config/' . $class . '.php',
        APP_ROOT . '/src/Models/' . $class . '.php',
        APP_ROOT . '/src/Services/' . $class . '.php',
        APP_ROOT . '/src/Controllers/' . $class . '.php',
    ];

    foreach ($paths as $path) {
        if (file_exists($path)) {
            require_once $path;
            return;
        }
    }
});
