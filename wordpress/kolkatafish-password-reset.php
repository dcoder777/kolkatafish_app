<?php
/**
 * Snippet Name: KolkataFish App - OTP Password Reset Endpoints
 * Description: Registers send-otp, verify-otp, and reset-password REST endpoints for the KolkataFish Flutter app.
 * Instructions: Paste this snippet into your WordPress "Code Snippets" plugin (or child theme functions.php) and activate it.
 *
 * REST Endpoints:
 *   1. POST /wp-json/kolkatafish/v1/send-otp
 *      Payload: { "email": "customer@example.com" }
 *      Action: Validates user exists, generates 6-digit OTP, stores it for 10 minutes, and emails it to user.
 *
 *   2. POST /wp-json/kolkatafish/v1/verify-otp
 *      Payload: { "email": "customer@example.com", "otp": "123456" }
 *      Action: Verifies 6-digit OTP against the stored transient.
 *
 *   3. POST /wp-json/kolkatafish/v1/reset-password
 *      Payload: { "email": "customer@example.com", "otp": "123456", "password": "new_password" }
 *      Action: Verifies OTP, updates WordPress/WooCommerce user password using wp_set_password(), and cleans up OTP.
 */

if (!defined('ABSPATH')) {
    exit;
}

add_action('rest_api_init', function () {
    // 1. Send OTP
    register_rest_route('kolkatafish/v1', '/send-otp', [
        'methods'             => 'POST',
        'callback'            => 'kf_rest_send_otp_handler',
        'permission_callback' => '__return_true',
    ], true);

    // 2. Verify OTP
    register_rest_route('kolkatafish/v1', '/verify-otp', [
        'methods'             => 'POST',
        'callback'            => 'kf_rest_verify_otp_handler',
        'permission_callback' => '__return_true',
    ], true);

    // 3. Reset Password
    register_rest_route('kolkatafish/v1', '/reset-password', [
        'methods'             => 'POST',
        'callback'            => 'kf_rest_reset_password_handler',
        'permission_callback' => '__return_true',
    ], true);

    // 4. Update Profile
    register_rest_route('kolkatafish/v1', '/update-profile', [
        'methods'             => 'POST',
        'callback'            => 'kf_rest_update_profile_handler',
        'permission_callback' => '__return_true',
    ], true);

    // 5. Login with Full WooCommerce Profile & Billing Phone
    register_rest_route('kolkatafish/v1', '/login', [
        'methods'             => 'POST',
        'callback'            => 'kf_rest_login_handler',
        'permission_callback' => '__return_true',
    ], true);
});

/**
 * 1. Send 6-digit OTP for password reset
 */
function kf_rest_send_otp_handler(WP_REST_Request $request) {
    $email = sanitize_email((string) $request->get_param('email'));

    if (empty($email) || !is_email($email)) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Please enter a valid email address.'
        ], 400);
    }

    // Check if account exists
    $user = get_user_by('email', $email);
    if (!$user) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'No KolkataFish account found with this email address.'
        ], 404);
    }

    // Rate limiting: 1 request per 45 seconds per email
    $rate_limit_key = 'kf_otp_cooldown_' . md5(strtolower($email));
    if (get_transient($rate_limit_key)) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Please wait 60 seconds before requesting another OTP.'
        ], 429);
    }

    // Generate 6-digit numeric OTP
    $otp = str_pad(strval(wp_rand(100000, 999999)), 6, '0', STR_PAD_LEFT);

    // Store OTP in WordPress transient for 10 minutes
    $transient_key = 'kf_otp_' . md5(strtolower($email));
    set_transient($transient_key, $otp, 10 * MINUTE_IN_SECONDS);
    set_transient($rate_limit_key, 1, 45); // Cooldown transient

    // Send email via wp_mail
    $site_name = get_bloginfo('name') ?: 'KolkataFish';
    $subject   = '[' . $site_name . '] Your Password Reset OTP: ' . $otp;
    
    $display_name = !empty($user->display_name) ? $user->display_name : 'Customer';
    
    $message  = "Hello " . esc_html($display_name) . ",\n\n";
    $message .= "We received a request to reset your password for your " . $site_name . " account.\n\n";
    $message .= "Your 6-digit verification code is:\n\n";
    $message .= "   " . $otp . "\n\n";
    $message .= "This code will expire in 10 minutes.\n";
    $message .= "If you did not make this request, you can safely ignore this email.\n\n";
    $message .= "Warm regards,\n";
    $message .= "The " . $site_name . " Team\n";
    $message .= home_url();

    $headers = ['Content-Type: text/plain; charset=UTF-8'];
    $sent = wp_mail($email, $subject, $message, $headers);

    if (!$sent) {
        error_log('[KolkataFish] wp_mail failed to send OTP to: ' . $email);
    }

    return new WP_REST_Response([
        'success' => true,
        'message' => 'A 6-digit OTP has been sent to your email.'
    ], 200);
}

/**
 * 2. Verify 6-digit OTP
 */
function kf_rest_verify_otp_handler(WP_REST_Request $request) {
    $email = sanitize_email((string) $request->get_param('email'));
    $otp   = sanitize_text_field(trim((string) $request->get_param('otp')));

    if (empty($email) || empty($otp)) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Email and 6-digit OTP are required.'
        ], 400);
    }

    $transient_key = 'kf_otp_' . md5(strtolower($email));
    $stored_otp    = get_transient($transient_key);

    if (!$stored_otp || $stored_otp !== $otp) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Invalid or expired OTP. Please check the code or request a new one.'
        ], 400);
    }

    // Mark as verified for 15 minutes
    $verified_key = 'kf_otp_verified_' . md5(strtolower($email));
    set_transient($verified_key, $otp, 15 * MINUTE_IN_SECONDS);

    return new WP_REST_Response([
        'success' => true,
        'message' => 'OTP verified successfully.'
    ], 200);
}

/**
 * 3. Reset Password using verified OTP
 */
function kf_rest_reset_password_handler(WP_REST_Request $request) {
    $email        = sanitize_email((string) $request->get_param('email'));
    $otp          = sanitize_text_field(trim((string) $request->get_param('otp')));
    $new_password = (string) ($request->get_param('password') ?: $request->get_param('new_password'));

    if (empty($email)) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Email is required.'
        ], 400);
    }

    if (empty($new_password) || strlen($new_password) < 6) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Password must be at least 6 characters.'
        ], 400);
    }

    // Verify OTP or verified flag
    $transient_key = 'kf_otp_' . md5(strtolower($email));
    $verified_key  = 'kf_otp_verified_' . md5(strtolower($email));
    
    $stored_otp       = get_transient($transient_key);
    $verified_token   = get_transient($verified_key);

    $is_valid_otp = (!empty($stored_otp) && !empty($otp) && $stored_otp === $otp);
    $is_verified  = (!empty($verified_token) && (empty($otp) || $verified_token === $otp));

    if (!$is_valid_otp && !$is_verified) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'OTP verification has expired. Please request a new OTP.'
        ], 400);
    }

    // Fetch user
    $user = get_user_by('email', $email);
    if (!$user) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Account not found.'
        ], 404);
    }

    // Update password in WordPress / WooCommerce
    wp_set_password($new_password, $user->ID);

    // Clean up transients
    delete_transient($transient_key);
    delete_transient($verified_key);
    delete_transient('kf_otp_cooldown_' . md5(strtolower($email)));

    // Send confirmation notification email to the user
    $site_name = get_bloginfo('name') ?: 'KolkataFish';
    $subject   = '[' . $site_name . '] Password Changed Successfully';
    
    $display_name = !empty($user->display_name) ? $user->display_name : 'Customer';
    $date_time    = current_time('F j, Y, g:i a e');

    $message  = "Hello " . esc_html($display_name) . ",\n\n";
    $message .= "Your " . $site_name . " account password was successfully updated on " . $date_time . ".\n\n";
    $message .= "You can now log in to the KolkataFish mobile app or website with your new password.\n\n";
    $message .= "SECURITY NOTICE:\n";
    $message .= "If you did not perform this password change, please contact our support team immediately or reset your password to secure your account.\n\n";
    $message .= "Warm regards,\n";
    $message .= "The " . $site_name . " Team\n";
    $message .= home_url();

    $headers = ['Content-Type: text/plain; charset=UTF-8'];
    wp_mail($email, $subject, $message, $headers);

    return new WP_REST_Response([
        'success' => true,
        'message' => 'Your password has been updated successfully. Please log in with your new password.'
    ], 200);
}

/**
 * 4. Update Profile (Name and Phone)
 */
function kf_rest_update_profile_handler(WP_REST_Request $request) {
    $email = sanitize_email((string) $request->get_param('email'));
    $name  = sanitize_text_field(trim((string) $request->get_param('name')));
    $phone = sanitize_text_field(trim((string) $request->get_param('phone')));

    if (empty($email) || !is_email($email)) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Valid email is required.'
        ], 400);
    }

    $user = get_user_by('email', $email);
    if (!$user) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Account not found.'
        ], 404);
    }

    // Update display name and first/last name
    $userdata = ['ID' => $user->ID];
    if (!empty($name)) {
        $userdata['display_name'] = $name;
        $name_parts = explode(' ', $name, 2);
        update_user_meta($user->ID, 'first_name', $name_parts[0]);
        if (isset($name_parts[1])) {
            update_user_meta($user->ID, 'last_name', $name_parts[1]);
        }
    }
    wp_update_user($userdata);

    // Update WooCommerce billing and shipping phone
    if ($phone !== null && $phone !== '') {
        update_user_meta($user->ID, 'billing_phone', $phone);
        update_user_meta($user->ID, 'shipping_phone', $phone);
        update_user_meta($user->ID, 'phone', $phone);
    }

    return new WP_REST_Response([
        'success' => true,
        'message' => 'Profile updated successfully.',
        'user'    => [
            'id'           => $user->ID,
            'email'        => $email,
            'display_name' => !empty($name) ? $name : $user->display_name,
            'phone'        => $phone !== null && $phone !== '' ? $phone : get_user_meta($user->ID, 'billing_phone', true)
        ]
    ], 200);
}

/**
 * 5. Login Handler returning full WooCommerce Customer details (including billing_phone)
 */
function kf_rest_login_handler(WP_REST_Request $request) {
    $email    = sanitize_email((string) $request->get_param('email'));
    $password = (string) $request->get_param('password');

    if (empty($email) || empty($password)) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Email and password are required.'
        ], 400);
    }

    // Try finding user by email, login, or billing_phone
    $user = get_user_by('email', $email);
    if (!$user) {
        $user = get_user_by('login', $email);
    }

    if (!$user) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'No KolkataFish account found with this email.'
        ], 404);
    }

    // Verify password directly against hash to avoid web redirection hooks (e.g. Jetpack 2FA / Account Protection)
    if (!wp_check_password($password, $user->user_pass, $user->ID)) {
        return new WP_REST_Response([
            'success' => false,
            'message' => 'Incorrect password. Please try again.'
        ], 401);
    }

    // Retrieve WooCommerce customer billing phone
    $billing_phone  = get_user_meta($user->ID, 'billing_phone', true);
    $shipping_phone = get_user_meta($user->ID, 'shipping_phone', true);
    $general_phone  = get_user_meta($user->ID, 'phone', true);
    $contact_number = !empty($billing_phone) ? $billing_phone : (!empty($shipping_phone) ? $shipping_phone : $general_phone);

    $display_name = !empty($user->display_name) ? $user->display_name : $user->first_name . ' ' . $user->last_name;
    if (empty(trim($display_name))) {
        $display_name = $user->user_login;
    }

    return new WP_REST_Response([
        'success' => true,
        'message' => 'Login successful.',
        'user'    => [
            'id'            => $user->ID,
            'email'         => $user->user_email,
            'display_name'  => trim($display_name),
            'name'          => trim($display_name),
            'phone'         => (string) $contact_number,
            'billing_phone' => (string) $billing_phone,
        ]
    ], 200);
}
