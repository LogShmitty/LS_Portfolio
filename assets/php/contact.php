<?php
// Enable error reporting for development purposes
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Collect and sanitize input data
    $name = htmlspecialchars(trim($_POST['demo-name']));
    $email = htmlspecialchars(trim($_POST['demo-email']));
    $category = htmlspecialchars(trim($_POST['demo-category']));
    $priority = isset($_POST['demo-priority']) ? $_POST['demo-priority'] : '';
    $copy = isset($_POST['demo-copy']) ? 'Yes' : 'No';
    $human = isset($_POST['demo-human']) ? 'Yes' : 'No';
    $message = htmlspecialchars(trim($_POST['demo-message']));

    // Validate input data
    if (empty($name) || empty($email) || empty($category) || empty($priority) || empty($message)) {
        echo "All fields are required.";
        exit;
    }

    // Send email using PHP's mail() function
    $to = 'loganevsmith@gmail.com';
    $subject = 'Website Form New Submission';
    $body = "Name: $name\n";
    $body .= "Email: $email\n";
    $body .= "Category: $category\n";
    $body .= "Priority: $priority\n";
    $body .= "Copy: $copy\n";
    $body .= "Human: $human\n";
    $body .= "Message:\n$message";

    if (mail($to, $subject, $body)) {
        echo "Thank you for your message!";
    } else {
        // Display error message from mail() function
        echo "Failed to send email. Error: " . error_get_last()['message'];
    }
} else {
    echo "Invalid request method.";
}
?>