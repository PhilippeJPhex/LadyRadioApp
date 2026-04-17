<?php
/**
 * Plugin Name: Lady Radio App Banners
 * Plugin URI: https://ladyradio.it
 * Description: Gestisce i banner sponsorizzati per l'App Mobile Flutter di Lady Radio.
 * Version: 1.0.0
 * Author: Borda AI
 * Author URI: https://ladyradio.it
 * Text Domain: ladyradio-app-banners
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

class LadyRadioAppBanners {

    public function __construct() {
        add_action('init', array($this, 'register_post_type'));
        add_action('add_meta_boxes', array($this, 'add_banner_meta_boxes'));
        add_action('save_post', array($this, 'save_banner_meta_box_data'));
        
        // Setup REST API endpoints
        add_action('rest_api_init', array($this, 'register_rest_endpoints'));
    }

    /**
     * Registra il Custom Post Type "Banners App"
     */
    public function register_post_type() {
        $labels = array(
            'name'                  => 'Banners App',
            'singular_name'         => 'Banner App',
            'menu_name'             => 'Banners App',
            'name_admin_bar'        => 'Banner App',
            'add_new'               => 'Aggiungi Nuovo',
            'add_new_item'          => 'Aggiungi Nuovo Banner',
            'new_item'              => 'Nuovo Banner',
            'edit_item'             => 'Modifica Banner',
            'view_item'             => 'Visualizza Banner',
            'all_items'             => 'Tutti i Banner',
            'search_items'          => 'Cerca Banner',
            'not_found'             => 'Nessun banner trovato.',
        );

        $args = array(
            'labels'             => $labels,
            'public'             => false,
            'publicly_queryable' => false,
            'show_ui'            => true,
            'show_in_menu'       => true,
            'query_var'          => false,
            'rewrite'            => false,
            'capability_type'    => 'post',
            'has_archive'        => false,
            'hierarchical'       => false,
            'menu_position'      => 20,
            'menu_icon'          => 'dashicons-smartphone', // Icona del telefono
            'supports'           => array('title', 'thumbnail'), // Usa title per nome campagna e thumbnail per l'immagine
        );

        register_post_type('lr_app_banner', $args);
    }

    /**
     * Aggiunge i Meta Box per i dettagli della campagna (Url, Date, Stats)
     */
    public function add_banner_meta_boxes() {
        add_meta_box(
            'lr_banner_details',
            'Dettagli Campagna Banner',
            array($this, 'render_banner_details_meta_box'),
            'lr_app_banner',
            'normal',
            'high'
        );
        add_meta_box(
            'lr_banner_stats',
            'Statistiche (App Mobile)',
            array($this, 'render_banner_stats_meta_box'),
            'lr_app_banner',
            'side',
            'default'
        );
    }

    public function render_banner_details_meta_box($post) {
        wp_nonce_field('lr_save_banner_data', 'lr_banner_meta_box_nonce');

        $target_url = get_post_meta($post->ID, '_lr_banner_target_url', true);
        $start_date = get_post_meta($post->ID, '_lr_banner_start_date', true);
        $end_date = get_post_meta($post->ID, '_lr_banner_end_date', true);

        echo '<div style="padding: 10px 0;">';
        echo '<label for="lr_banner_target_url" style="display:block; font-weight:bold; margin-bottom:5px;">Link di Destinazione (URL):</label>';
        echo '<input type="url" id="lr_banner_target_url" name="lr_banner_target_url" value="' . esc_attr($target_url) . '" style="width:100%;" placeholder="https://..." />';
        echo '<p class="description">Dove atterra l\'utente quando tocca il banner sull\'app.</p>';
        echo '</div>';

        echo '<div style="padding: 10px 0;">';
        echo '<label for="lr_banner_start_date" style="display:block; font-weight:bold; margin-bottom:5px;">Data e Ora di Inizio:</label>';
        echo '<input type="datetime-local" id="lr_banner_start_date" name="lr_banner_start_date" value="' . esc_attr($start_date) . '" />';
        echo '</div>';

        echo '<div style="padding: 10px 0;">';
        echo '<label for="lr_banner_end_date" style="display:block; font-weight:bold; margin-bottom:5px;">Data e Ora di Fine:</label>';
        echo '<input type="datetime-local" id="lr_banner_end_date" name="lr_banner_end_date" value="' . esc_attr($end_date) . '" />';
        echo '<p class="description">Seleziona i limiti nel tempo durante i quali il banner sar&agrave; mostrato nell\'App. L\'App chieder&agrave; a WP solo quello in corso.</p>';
        echo '</div>';
    }

    public function render_banner_stats_meta_box($post) {
        $impressions = get_post_meta($post->ID, '_lr_banner_impressions', true) ?: 0;
        $clicks = get_post_meta($post->ID, '_lr_banner_clicks', true) ?: 0;

        echo '<ul style="font-size: 14px; margin: 0; padding: 0; list-style: none;">';
        echo '<li style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Visualizzazioni (Impressions):</strong> <span style="font-size:16px; color:#2271b1;">' . esc_html($impressions) . '</span></li>';
        echo '<li style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Click Totali:</strong> <span style="font-size:16px; color:#d63638;">' . esc_html($clicks) . '</span></li>';
        echo '</ul>';
        echo '<p class="description">Questi dati si aggiornano automaticamente in tempo reale dai telefoni degli utenti. Non sono modificabili manualmente.</p>';
    }

    public function save_banner_meta_box_data($post_id) {
        if (!isset($_POST['lr_banner_meta_box_nonce'])) return;
        if (!wp_verify_nonce($_POST['lr_banner_meta_box_nonce'], 'lr_save_banner_data')) return;
        if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) return;
        if (!current_user_can('edit_post', $post_id)) return;

        if (isset($_POST['lr_banner_target_url'])) {
            update_post_meta($post_id, '_lr_banner_target_url', sanitize_url($_POST['lr_banner_target_url']));
        }
        if (isset($_POST['lr_banner_start_date'])) {
            update_post_meta($post_id, '_lr_banner_start_date', sanitize_text_field($_POST['lr_banner_start_date']));
        }
        if (isset($_POST['lr_banner_end_date'])) {
            update_post_meta($post_id, '_lr_banner_end_date', sanitize_text_field($_POST['lr_banner_end_date']));
        }

        // Initialize stats if they don't exist yet
        if (get_post_meta($post_id, '_lr_banner_impressions', true) === '') {
            update_post_meta($post_id, '_lr_banner_impressions', 0);
        }
        if (get_post_meta($post_id, '_lr_banner_clicks', true) === '') {
            update_post_meta($post_id, '_lr_banner_clicks', 0);
        }
    }

    /**
     * REGISTRAZIONE DELLE REST API
     */
    public function register_rest_endpoints() {
        $namespace = 'ladyapp/v1';

        // 1. GET Active Banner
        register_rest_route($namespace, '/active-banner', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_active_banner'),
            'permission_callback' => '__return_true', // Public
        ));

        // 2. POST Track Impression
        register_rest_route($namespace, '/track-impression', array(
            'methods' => 'POST',
            'callback' => array($this, 'track_impression'),
            'permission_callback' => '__return_true', 
        ));

        // 3. POST Track Click
        register_rest_route($namespace, '/track-click', array(
            'methods' => 'POST',
            'callback' => array($this, 'track_click'),
            'permission_callback' => '__return_true', 
        ));
    }

    public function get_active_banner($request) {
        $now = current_time('Y-m-d\TH:i');

        $args = array(
            'post_type' => 'lr_app_banner',
            'post_status' => 'publish',
            'posts_per_page' => 1,
            'meta_query' => array(
                'relation' => 'AND',
                array(
                    'key' => '_lr_banner_start_date',
                    'value' => $now,
                    'compare' => '<=',
                    'type' => 'DATETIME'
                ),
                array(
                    'key' => '_lr_banner_end_date',
                    'value' => $now,
                    'compare' => '>=',
                    'type' => 'DATETIME'
                )
            ),
            'orderby' => 'date',
            'order' => 'DESC'
        );

        $query = new WP_Query($args);

        if ($query->have_posts()) {
            $post = $query->posts[0];
            $image_id = get_post_thumbnail_id($post->ID);
            $image_url = wp_get_attachment_image_url($image_id, 'full');
            
            // Fallback securely logic if no thumbnail is set
            if (!$image_url) {
                 return new WP_REST_Response(array('error' => 'No image set for the active banner.'), 404);
            }

            $target_url = get_post_meta($post->ID, '_lr_banner_target_url', true);

            $response = array(
                'id' => (string) $post->ID, // important to be string for Flutter side matching if needed
                'imageUrl' => $image_url,
                'targetUrl' => $target_url,
            );

            return new WP_REST_Response($response, 200);
        }

        return new WP_REST_Response(array('message' => 'No active banner right now.'), 404);
    }

    public function track_impression($request) {
        $parameters = $request->get_json_params() ?: $request->get_body_params();
        $banner_id = isset($parameters['bannerId']) ? intval($parameters['bannerId']) : 0;

        if ($banner_id > 0 && get_post_type($banner_id) === 'lr_app_banner') {
            $current_impressions = intval(get_post_meta($banner_id, '_lr_banner_impressions', true));
            update_post_meta($banner_id, '_lr_banner_impressions', $current_impressions + 1);
            return new WP_REST_Response(array('success' => true), 200);
        }

        return new WP_REST_Response(array('success' => false, 'error' => 'Invalid banner ID'), 400);
    }

    public function track_click($request) {
        $parameters = $request->get_json_params() ?: $request->get_body_params();
        $banner_id = isset($parameters['bannerId']) ? intval($parameters['bannerId']) : 0;

        if ($banner_id > 0 && get_post_type($banner_id) === 'lr_app_banner') {
            $current_clicks = intval(get_post_meta($banner_id, '_lr_banner_clicks', true));
            update_post_meta($banner_id, '_lr_banner_clicks', $current_clicks + 1);
            return new WP_REST_Response(array('success' => true), 200);
        }

        return new WP_REST_Response(array('success' => false, 'error' => 'Invalid banner ID'), 400);
    }
}

// Inizializza il plugin
new LadyRadioAppBanners();
