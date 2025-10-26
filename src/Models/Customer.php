<?php
/**
 * Customer Model
 * Handles customer data operations
 */

class Customer {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance();
    }

    /**
     * Find or create customer by phone number
     */
    public function findOrCreateByPhone($phone) {
        // Normalize phone number
        $phone = $this->normalizePhone($phone);

        $customer = $this->db->fetchOne(
            "SELECT * FROM customers WHERE phone = ?",
            [$phone]
        );

        if (!$customer) {
            $customerId = $this->db->insert('customers', [
                'phone' => $phone
            ]);

            $customer = $this->db->fetchOne(
                "SELECT * FROM customers WHERE id = ?",
                [$customerId]
            );
        }

        return $customer;
    }

    /**
     * Get customer by ID
     */
    public function findById($id) {
        return $this->db->fetchOne(
            "SELECT * FROM customers WHERE id = ?",
            [$id]
        );
    }

    /**
     * Update customer information
     */
    public function update($id, $data) {
        $this->db->update('customers', $data, 'id = :id', ['id' => $id]);
    }

    /**
     * Link customer to Brains account
     */
    public function linkBrainsAccount($customerId, $accountData) {
        $this->db->update('customers', [
            'brains_account_code' => $accountData['AccoCode'] ?? null,
            'name' => $accountData['AccoName'] ?? null,
            'email' => $accountData['Email'] ?? null,
            'balance' => $accountData['Balance'] ?? 0,
            'credit_limit' => $accountData['CreditLimit'] ?? 0,
            'address' => $accountData['Address'] ?? null
        ], 'id = :id', ['id' => $customerId]);
    }

    /**
     * Get customer with conversation history
     */
    public function getWithMessages($customerId, $limit = 10) {
        $customer = $this->findById($customerId);
        if (!$customer) return null;

        $messages = $this->db->fetchAll(
            "SELECT * FROM messages
             WHERE customer_id = ?
             ORDER BY created_at DESC
             LIMIT ?",
            [$customerId, $limit]
        );

        $customer['recent_messages'] = array_reverse($messages);
        return $customer;
    }

    /**
     * Get all customers with stats
     */
    public function getAllWithStats() {
        return $this->db->fetchAll(
            "SELECT
                c.*,
                COUNT(DISTINCT m.id) as message_count,
                COUNT(DISTINCT o.id) as order_count,
                MAX(m.created_at) as last_message_at
             FROM customers c
             LEFT JOIN messages m ON c.id = m.customer_id
             LEFT JOIN orders o ON c.id = o.customer_id
             GROUP BY c.id
             ORDER BY last_message_at DESC"
        );
    }

    /**
     * Search customers
     */
    public function search($query) {
        $searchTerm = "%{$query}%";
        return $this->db->fetchAll(
            "SELECT * FROM customers
             WHERE phone LIKE ?
                OR name LIKE ?
                OR brains_account_code LIKE ?
             LIMIT 50",
            [$searchTerm, $searchTerm, $searchTerm]
        );
    }

    /**
     * Normalize phone number (remove spaces, add +961 if needed)
     */
    private function normalizePhone($phone) {
        // Remove spaces and special characters
        $phone = preg_replace('/[^0-9+]/', '', $phone);

        // If starts with 0, replace with +961
        if (strpos($phone, '0') === 0) {
            $phone = '+961' . substr($phone, 1);
        }

        // If doesn't start with +, add +961
        if (strpos($phone, '+') !== 0) {
            $phone = '+961' . $phone;
        }

        return $phone;
    }

    /**
     * Get customer statistics
     */
    public function getStats() {
        $stats = $this->db->fetchOne(
            "SELECT
                COUNT(*) as total_customers,
                COUNT(CASE WHEN brains_account_code IS NOT NULL THEN 1 END) as linked_customers,
                COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as new_this_week
             FROM customers"
        );

        return $stats;
    }
}
