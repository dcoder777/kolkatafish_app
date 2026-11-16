<?php
/**
 * Snippet Name: KolkataFish - WooCommerce Order Delivery Slots Sync & Admin Columns
 * Description: Syncs delivery date and delivery time slot from Flutter app Store API checkout into WooCommerce order meta (_delivery_date, _delivery_time, add_delivery_date, add_delivery_time), registers the /wp-json/kolkatafish/v1/set-order-delivery endpoint, and adds "Delivery Date" & "Delivery Slot" columns to the WooCommerce admin orders table.
 *
 * Instructions:
 *   Option A (Recommended): Paste into WordPress "Code Snippets" plugin (or child theme functions.php) and click "Activate".
 *   Option B: Included in the KolkataFish Shop Customizer plugin.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * 1. Hook into WooCommerce Store API checkout to save delivery date and slot to order meta.
 */
add_action( 'woocommerce_store_api_checkout_order_processed', 'kf_sync_store_api_delivery_slots', 10, 1 );
function kf_sync_store_api_delivery_slots( $order ) {
	if ( ! $order instanceof \WC_Order ) {
		return;
	}

	$order_id      = $order->get_id();
	$delivery_date = '';
	$delivery_slot = '';

	// A. Check raw JSON payload from Store API request
	$raw_input = file_get_contents( 'php://input' );
	if ( ! empty( $raw_input ) ) {
		$body = json_decode( $raw_input, true );
		if ( is_array( $body ) ) {
			$delivery_date = $body['add_delivery_date'] ?? $body['delivery_date'] ?? $body['_delivery_date'] ?? '';
			$delivery_slot = $body['add_delivery_time'] ?? $body['delivery_slot'] ?? $body['delivery_time'] ?? $body['_delivery_time'] ?? '';

			// Check nested additional_fields or extensions
			if ( empty( $delivery_date ) && ! empty( $body['additional_fields']['add_delivery_date'] ) ) {
				$delivery_date = $body['additional_fields']['add_delivery_date'];
			}
			if ( empty( $delivery_slot ) && ! empty( $body['additional_fields']['add_delivery_time'] ) ) {
				$delivery_slot = $body['additional_fields']['add_delivery_time'];
			}
		}
	}

	// B. Fallback: Parse from customer_note (where KolkataFish Flutter app always writes the slot)
	if ( empty( $delivery_date ) || empty( $delivery_slot ) ) {
		$note = $order->get_customer_note();
		if ( ! empty( $note ) ) {
			if ( empty( $delivery_date ) && preg_match( '/(?:Delivery Date|add_delivery_date):\s*([^\r\n]+)/i', $note, $m ) ) {
				$delivery_date = trim( $m[1] );
			}
			if ( empty( $delivery_slot ) && preg_match( '/(?:Delivery Slot|add_delivery_time|delivery_slot|delivery_time):\s*([^\r\n]+)/i', $note, $m ) ) {
				$delivery_slot = trim( $m[1] );
			}
		}
	}

	if ( ! empty( $delivery_date ) || ! empty( $delivery_slot ) ) {
		kf_persist_order_delivery_meta( $order, $delivery_date, $delivery_slot );
	}
}

/**
 * 2. Helper function to persist delivery meta across HPOS and postmeta.
 */
function kf_persist_order_delivery_meta( $order, $delivery_date, $delivery_slot ) {
	if ( ! $order instanceof \WC_Order ) {
		$order = wc_get_order( $order );
		if ( ! $order ) {
			return;
		}
	}
	$order_id = $order->get_id();

	if ( ! empty( $delivery_date ) ) {
		$date_clean = sanitize_text_field( $delivery_date );
		$order->update_meta_data( '_delivery_date', $date_clean );
		$order->update_meta_data( 'add_delivery_date', $date_clean );
		$order->update_meta_data( 'delivery_date', $date_clean );
		update_post_meta( $order_id, '_delivery_date', $date_clean );
		update_post_meta( $order_id, 'add_delivery_date', $date_clean );
		update_post_meta( $order_id, 'delivery_date', $date_clean );
	}

	if ( ! empty( $delivery_slot ) ) {
		$slot_clean = sanitize_text_field( $delivery_slot );
		$order->update_meta_data( '_delivery_time', $slot_clean );
		$order->update_meta_data( 'add_delivery_time', $slot_clean );
		$order->update_meta_data( 'delivery_slot', $slot_clean );
		$order->update_meta_data( 'delivery_time', $slot_clean );
		update_post_meta( $order_id, '_delivery_time', $slot_clean );
		update_post_meta( $order_id, 'add_delivery_time', $slot_clean );
		update_post_meta( $order_id, 'delivery_slot', $slot_clean );
		update_post_meta( $order_id, 'delivery_time', $slot_clean );
	}

	$order->save();
}

/**
 * 3. Dedicated REST Endpoint: POST /wp-json/kolkatafish/v1/set-order-delivery
 * Used by the Flutter app to directly set/verify order delivery slots upon checkout.
 */
add_action( 'rest_api_init', function() {
	register_rest_route( 'kolkatafish/v1', '/set-order-delivery', array(
		'methods'             => 'POST',
		'callback'            => 'kf_rest_set_order_delivery_endpoint',
		'permission_callback' => '__return_true',
	) );
} );

function kf_rest_set_order_delivery_endpoint( \WP_REST_Request $request ) {
	$order_id      = (int) $request->get_param( 'order_id' );
	$order_key     = sanitize_text_field( (string) $request->get_param( 'order_key' ) );
	$delivery_date = sanitize_text_field( (string) $request->get_param( 'delivery_date' ) );
	$delivery_slot = sanitize_text_field( (string) $request->get_param( 'delivery_slot' ) );

	if ( $order_id <= 0 ) {
		return new \WP_REST_Response( array(
			'success' => false,
			'message' => 'Invalid order ID.',
		), 400 );
	}

	$order = wc_get_order( $order_id );
	if ( ! $order ) {
		return new \WP_REST_Response( array(
			'success' => false,
			'message' => 'Order not found.',
		), 404 );
	}

	// Security: Verify order key so arbitrary orders cannot be updated without order key
	if ( ! empty( $order_key ) && $order->get_order_key() !== $order_key ) {
		return new \WP_REST_Response( array(
			'success' => false,
			'message' => 'Invalid order key.',
		), 403 );
	}

	kf_persist_order_delivery_meta( $order, $delivery_date, $delivery_slot );

	return new \WP_REST_Response( array(
		'success'       => true,
		'order_id'      => $order_id,
		'delivery_date' => $delivery_date,
		'delivery_slot' => $delivery_slot,
	), 200 );
}

/**
 * 4. Add "Delivery Date" & "Delivery Slot" columns to WooCommerce Admin Orders Table.
 * Supports both Legacy CPT (posts) and HPOS (High-Performance Order Storage).
 */

// Legacy CPT Orders Table columns
add_filter( 'manage_edit-shop_order_columns', 'kf_add_order_admin_columns', 25 );
add_action( 'manage_shop_order_posts_custom_column', 'kf_render_legacy_order_column', 25, 2 );

// HPOS Orders Table columns
add_filter( 'manage_woocommerce_page_wc-orders_columns', 'kf_add_order_admin_columns', 25 );
add_action( 'manage_woocommerce_page_wc-orders_custom_column', 'kf_render_hpos_order_column', 25, 2 );

function kf_add_order_admin_columns( $columns ) {
	$new_columns = array();
	foreach ( $columns as $key => $column ) {
		$new_columns[ $key ] = $column;
		if ( 'order_status' === $key || 'order_date' === $key ) {
			$new_columns['kf_delivery_date'] = __( 'Delivery Date', 'kolkatafish' );
			$new_columns['kf_delivery_slot'] = __( 'Delivery Slot', 'kolkatafish' );
		}
	}
	if ( ! isset( $new_columns['kf_delivery_slot'] ) ) {
		$new_columns['kf_delivery_date'] = __( 'Delivery Date', 'kolkatafish' );
		$new_columns['kf_delivery_slot'] = __( 'Delivery Slot', 'kolkatafish' );
	}
	return $new_columns;
}

function kf_get_order_delivery_values( $order_or_id ) {
	$order = $order_or_id instanceof \WC_Order ? $order_or_id : wc_get_order( $order_or_id );
	if ( ! $order ) {
		return array( 'date' => '', 'slot' => '' );
	}

	$date = $order->get_meta( '_delivery_date' ) ?: $order->get_meta( 'add_delivery_date' ) ?: $order->get_meta( 'delivery_date' );
	$slot = $order->get_meta( '_delivery_time' ) ?: $order->get_meta( 'add_delivery_time' ) ?: $order->get_meta( 'delivery_slot' ) ?: $order->get_meta( 'delivery_time' );

	// Auto-recovery for existing orders: if empty, extract from customer note on-the-fly and save!
	if ( empty( $date ) || empty( $slot ) ) {
		$note = $order->get_customer_note();
		if ( ! empty( $note ) ) {
			if ( empty( $date ) && preg_match( '/(?:Delivery Date|add_delivery_date):\s*([^\r\n]+)/i', $note, $m ) ) {
				$date = trim( $m[1] );
			}
			if ( empty( $slot ) && preg_match( '/(?:Delivery Slot|add_delivery_time|delivery_slot|delivery_time):\s*([^\r\n]+)/i', $note, $m ) ) {
				$slot = trim( $m[1] );
			}
			if ( ! empty( $date ) || ! empty( $slot ) ) {
				kf_persist_order_delivery_meta( $order, $date, $slot );
			}
		}
	}

	return array( 'date' => $date, 'slot' => $slot );
}

function kf_render_legacy_order_column( $column, $post_id ) {
	if ( 'kf_delivery_date' === $column ) {
		$vals = kf_get_order_delivery_values( $post_id );
		echo ! empty( $vals['date'] )
			? '<strong style="color:#1d2327;">' . esc_html( $vals['date'] ) . '</strong>'
			: '<span style="color:#999;">—</span>';
	} elseif ( 'kf_delivery_slot' === $column ) {
		$vals = kf_get_order_delivery_values( $post_id );
		echo ! empty( $vals['slot'] )
			? '<span style="display:inline-block;padding:3px 8px;border-radius:4px;background:#e7f5ea;color:#1e7e34;font-weight:600;font-size:12px;">' . esc_html( $vals['slot'] ) . '</span>'
			: '<span style="color:#999;">—</span>';
	}
}

function kf_render_hpos_order_column( $column, $order ) {
	if ( 'kf_delivery_date' === $column ) {
		$vals = kf_get_order_delivery_values( $order );
		echo ! empty( $vals['date'] )
			? '<strong style="color:#1d2327;">' . esc_html( $vals['date'] ) . '</strong>'
			: '<span style="color:#999;">—</span>';
	} elseif ( 'kf_delivery_slot' === $column ) {
		$vals = kf_get_order_delivery_values( $order );
		echo ! empty( $vals['slot'] )
			? '<span style="display:inline-block;padding:3px 8px;border-radius:4px;background:#e7f5ea;color:#1e7e34;font-weight:600;font-size:12px;">' . esc_html( $vals['slot'] ) . '</span>'
			: '<span style="color:#999;">—</span>';
	}
}
