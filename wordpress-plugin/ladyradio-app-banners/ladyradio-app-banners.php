<?php
/**
 * Plugin Name: Lady Radio App Banners
 * Plugin URI: https://ladyradio.it
 * Description: Gestisce i banner sponsorizzati per l'App Mobile Flutter di Lady Radio.
 * Version: 1.8.3
 * Author: Borda AI
 * Author URI: https://ladyradio.it
 * Text Domain: ladyradio-app-banners
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

class LadyRadioAppBannersPlugin_183
{

    public function __construct()
    {
        add_action('init', array($this, 'register_post_type'));
        add_action('add_meta_boxes', array($this, 'add_banner_meta_boxes'));
        add_action('save_post', array($this, 'save_banner_meta_box_data'));
        add_action('admin_menu', array($this, 'register_admin_menu'), 9);
        add_action('admin_init', array($this, 'register_settings'));

        // Setup REST API endpoints
        add_action('rest_api_init', array($this, 'register_rest_endpoints'));
    }

    public static function activate()
    {
        $plugin = new self();
        $plugin->register_post_type();
        flush_rewrite_rules();
    }

    public function register_admin_menu()
    {
        add_menu_page(
            'Banners App',
            'Banners App',
            'edit_posts',
            'edit.php?post_type=lr_app_banner',
            '',
            'dashicons-smartphone',
            20
        );

        add_submenu_page(
            'edit.php?post_type=lr_app_banner',
            'Tutti i Banner App',
            'Tutti i Banner',
            'edit_posts',
            'edit.php?post_type=lr_app_banner'
        );

        add_submenu_page(
            'edit.php?post_type=lr_app_banner',
            'Aggiungi Banner App',
            'Aggiungi Banner',
            'edit_posts',
            'post-new.php?post_type=lr_app_banner'
        );

        add_submenu_page(
            'edit.php?post_type=lr_app_banner',
            'Dirette Twitch App',
            'Dirette Twitch App',
            'edit_posts',
            'edit.php?post_type=lr_twitch_event'
        );

        add_submenu_page(
            'edit.php?post_type=lr_app_banner',
            'Aggiungi Diretta Twitch',
            'Aggiungi Diretta Twitch',
            'edit_posts',
            'post-new.php?post_type=lr_twitch_event'
        );

        add_submenu_page(
            'edit.php?post_type=lr_app_banner',
            'Fallback Banner App',
            'Fallback Banner',
            'manage_options',
            'lr-app-banner-fallback',
            array($this, 'render_settings_page')
        );
    }

    public function register_settings()
    {
        register_setting('lr_app_banner_settings', 'lr_app_banner_fallback_image_url', array(
            'type' => 'string',
            'sanitize_callback' => 'esc_url_raw',
            'default' => '',
        ));

        register_setting('lr_app_banner_settings', 'lr_app_banner_fallback_target_url', array(
            'type' => 'string',
            'sanitize_callback' => 'esc_url_raw',
            'default' => home_url('/'),
        ));
    }

    public function render_settings_page()
    {
        if (!current_user_can('manage_options')) {
            return;
        }

        $image_url = get_option('lr_app_banner_fallback_image_url', '');
        $target_url = get_option('lr_app_banner_fallback_target_url', home_url('/'));

        echo '<div class="wrap">';
        echo '<h1>Fallback Banner App</h1>';
        echo '<p>Questo banner viene mostrato nell&rsquo;app quando non ci sono campagne banner attive nel periodo corrente.</p>';
        echo '<form method="post" action="options.php">';
        settings_fields('lr_app_banner_settings');

        echo '<table class="form-table" role="presentation">';
        echo '<tr>';
        echo '<th scope="row"><label for="lr_app_banner_fallback_image_url">URL immagine fallback</label></th>';
        echo '<td>';
        echo '<input type="url" id="lr_app_banner_fallback_image_url" name="lr_app_banner_fallback_image_url" value="' . esc_attr($image_url) . '" class="regular-text" placeholder="https://..." />';
        echo '<p class="description">Inserisci l&rsquo;URL completo dell&rsquo;immagine banner. Lascia vuoto per non mostrare alcun fallback.</p>';
        echo '</td>';
        echo '</tr>';

        echo '<tr>';
        echo '<th scope="row"><label for="lr_app_banner_fallback_target_url">Link di destinazione fallback</label></th>';
        echo '<td>';
        echo '<input type="url" id="lr_app_banner_fallback_target_url" name="lr_app_banner_fallback_target_url" value="' . esc_attr($target_url) . '" class="regular-text" placeholder="https://..." />';
        echo '<p class="description">Dove aprire l&rsquo;utente quando tocca il fallback. Se vuoto, verr&agrave; usata la home del sito.</p>';
        echo '</td>';
        echo '</tr>';
        echo '</table>';

        submit_button('Salva fallback');
        echo '</form>';
        echo '</div>';
    }

    /**
     * Registra il Custom Post Type "Banners App"
     */
    public function register_post_type()
    {
        $labels = array(
            'name' => 'Banners App',
            'singular_name' => 'Banner App',
            'menu_name' => 'Banners App',
            'name_admin_bar' => 'Banner App',
            'add_new' => 'Aggiungi Nuovo',
            'add_new_item' => 'Aggiungi Nuovo Banner',
            'new_item' => 'Nuovo Banner',
            'edit_item' => 'Modifica Banner',
            'view_item' => 'Visualizza Banner',
            'all_items' => 'Tutti i Banner',
            'search_items' => 'Cerca Banner',
            'not_found' => 'Nessun banner trovato.',
        );

        $args = array(
            'labels' => $labels,
            'public' => false,
            'publicly_queryable' => false,
            'show_ui' => true,
            'show_in_menu' => false,
            'query_var' => false,
            'rewrite' => false,
            'capability_type' => 'post',
            'has_archive' => false,
            'hierarchical' => false,
            'supports' => array('title', 'thumbnail'), // Usa title per nome campagna e thumbnail per l'immagine
        );

        register_post_type('lr_app_banner', $args);

        $twitch_labels = array(
            'name' => 'Dirette Twitch App',
            'singular_name' => 'Diretta Twitch App',
            'menu_name' => 'Dirette Twitch App',
            'name_admin_bar' => 'Diretta Twitch App',
            'add_new' => 'Aggiungi Nuova',
            'add_new_item' => 'Aggiungi Nuova Diretta Twitch',
            'new_item' => 'Nuova Diretta Twitch',
            'edit_item' => 'Modifica Diretta Twitch',
            'view_item' => 'Visualizza Diretta Twitch',
            'all_items' => 'Tutte le Dirette Twitch',
            'search_items' => 'Cerca Dirette Twitch',
            'not_found' => 'Nessuna diretta Twitch trovata.',
        );

        $twitch_args = array(
            'labels' => $twitch_labels,
            'public' => false,
            'publicly_queryable' => false,
            'show_ui' => true,
            'show_in_menu' => false,
            'query_var' => false,
            'rewrite' => false,
            'capability_type' => 'post',
            'has_archive' => false,
            'hierarchical' => false,
            'supports' => array('title', 'thumbnail'),
        );

        register_post_type('lr_twitch_event', $twitch_args);

    }

    /**
     * Aggiunge i Meta Box per i dettagli della campagna (Url, Date, Stats)
     */
    public function add_banner_meta_boxes()
    {
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

        add_meta_box(
            'lr_twitch_details',
            'Dettagli Diretta Twitch',
            array($this, 'render_twitch_details_meta_box'),
            'lr_twitch_event',
            'normal',
            'high'
        );

    }

    public function render_banner_details_meta_box($post)
    {
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

        echo '<div style="padding: 12px; margin-top: 15px; border-left: 4px solid #d63638; background: #fff5f5;">';
        echo '<h2 style="margin:0 0 10px;font-size:1.2rem;color:#d63638;font-weight:800;">LA CACHE VIENE CANCELLATA AUTOMATICAMENTE QUANDO PREMI AGGIORNA.</h2>';
        echo '<p class="description" style="margin:0;">Dopo ogni modifica a date, link o immagine, salva il banner con il pulsante Aggiorna. Il plugin prover&agrave; a svuotare la cache WordPress e i plugin cache pi&ugrave; comuni.</p>';
        echo '</div>';
    }

    private function clear_known_caches()
    {
        $cleared = false;

        if (function_exists('wp_cache_flush')) {
            wp_cache_flush();
            $cleared = true;
        }

        if (function_exists('rocket_clean_domain')) {
            rocket_clean_domain();
            $cleared = true;
        }

        if (function_exists('w3tc_flush_all')) {
            w3tc_flush_all();
            $cleared = true;
        }

        if (function_exists('wp_cache_clear_cache')) {
            wp_cache_clear_cache();
            $cleared = true;
        }

        if (function_exists('sg_cachepress_purge_cache')) {
            sg_cachepress_purge_cache();
            $cleared = true;
        }

        if (class_exists('autoptimizeCache') && method_exists('autoptimizeCache', 'clearall')) {
            autoptimizeCache::clearall();
            $cleared = true;
        }

        if (function_exists('breeze_clear_all_cache')) {
            breeze_clear_all_cache();
            $cleared = true;
        }

        do_action('litespeed_purge_all');
        do_action('cache_flush');
        do_action('wp_cache_clear_cache');

        delete_transient('lr_app_active_banner');
        delete_transient('lr_app_schedule');
        delete_transient('lr_app_twitch_events');

        return $cleared;
    }

    public function render_banner_stats_meta_box($post)
    {
        $impressions = get_post_meta($post->ID, '_lr_banner_impressions', true) ?: 0;
        $clicks = get_post_meta($post->ID, '_lr_banner_clicks', true) ?: 0;

        echo '<ul style="font-size: 14px; margin: 0; padding: 0; list-style: none;">';
        echo '<li style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Visualizzazioni (Impressions):</strong> <span style="font-size:16px; color:#2271b1;">' . esc_html($impressions) . '</span></li>';
        echo '<li style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Click Totali:</strong> <span style="font-size:16px; color:#d63638;">' . esc_html($clicks) . '</span></li>';
        echo '</ul>';
        echo '<p class="description">Questi dati si aggiornano automaticamente in tempo reale dai telefoni degli utenti. Non sono modificabili manualmente.</p>';
    }

    public function render_twitch_details_meta_box($post)
    {
        wp_nonce_field('lr_save_twitch_data', 'lr_twitch_meta_box_nonce');

        $target_url = get_post_meta($post->ID, '_lr_twitch_target_url', true);
        $start_date = get_post_meta($post->ID, '_lr_twitch_start_date', true);
        $end_date = get_post_meta($post->ID, '_lr_twitch_end_date', true);

        echo '<div style="padding: 10px 0;">';
        echo '<label for="lr_twitch_target_url" style="display:block; font-weight:bold; margin-bottom:5px;">Link Twitch / destinazione:</label>';
        echo '<input type="url" id="lr_twitch_target_url" name="lr_twitch_target_url" value="' . esc_attr($target_url) . '" style="width:100%;" placeholder="https://www.twitch.tv/..." />';
        echo '<p class="description">Link aperto quando l&rsquo;utente tocca la locandina nell&rsquo;app.</p>';
        echo '</div>';

        echo '<div style="padding: 10px 0;">';
        echo '<label for="lr_twitch_start_date" style="display:block; font-weight:bold; margin-bottom:5px;">Data e ora della diretta:</label>';
        echo '<input type="datetime-local" id="lr_twitch_start_date" name="lr_twitch_start_date" value="' . esc_attr($start_date) . '" />';
        echo '<p class="description">La locandina appare nella sezione “Questa settimana su Twitch” se la diretta cade nei prossimi 7 giorni.</p>';
        echo '</div>';

        echo '<div style="padding: 10px 0;">';
        echo '<label for="lr_twitch_end_date" style="display:block; font-weight:bold; margin-bottom:5px;">Data e ora fine diretta:</label>';
        echo '<input type="datetime-local" id="lr_twitch_end_date" name="lr_twitch_end_date" value="' . esc_attr($end_date) . '" />';
        echo '<p class="description">Dopo questa data/ora la locandina sparisce automaticamente dall&rsquo;app.</p>';
        echo '</div>';

        echo '<div style="padding: 12px; margin-top: 15px; border-left: 4px solid #9146ff; background: #f7f1ff;">';
        echo '<p style="margin:0;"><strong>Immagine locandina:</strong> usa l&rsquo;immagine in evidenza del contenuto. Mantieni la stessa proporzione del banner app.</p>';
        echo '</div>';
    }


    public function save_banner_meta_box_data($post_id)
    {
        if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE)
            return;
        if (!current_user_can('edit_post', $post_id))
            return;

        // Banner Saving logic
        if (isset($_POST['lr_banner_meta_box_nonce']) && wp_verify_nonce($_POST['lr_banner_meta_box_nonce'], 'lr_save_banner_data')) {
            if (isset($_POST['lr_banner_target_url'])) {
                update_post_meta($post_id, '_lr_banner_target_url', sanitize_url($_POST['lr_banner_target_url']));
            }
            if (isset($_POST['lr_banner_start_date'])) {
                update_post_meta($post_id, '_lr_banner_start_date', sanitize_text_field($_POST['lr_banner_start_date']));
            }
            if (isset($_POST['lr_banner_end_date'])) {
                update_post_meta($post_id, '_lr_banner_end_date', sanitize_text_field($_POST['lr_banner_end_date']));
            }

            if (get_post_meta($post_id, '_lr_banner_impressions', true) === '') {
                update_post_meta($post_id, '_lr_banner_impressions', 0);
            }
            if (get_post_meta($post_id, '_lr_banner_clicks', true) === '') {
                update_post_meta($post_id, '_lr_banner_clicks', 0);
            }

            $this->clear_known_caches();
        }

        if (isset($_POST['lr_twitch_meta_box_nonce']) && wp_verify_nonce($_POST['lr_twitch_meta_box_nonce'], 'lr_save_twitch_data')) {
            if (isset($_POST['lr_twitch_target_url'])) {
                update_post_meta($post_id, '_lr_twitch_target_url', sanitize_url($_POST['lr_twitch_target_url']));
            }
            if (isset($_POST['lr_twitch_start_date'])) {
                update_post_meta($post_id, '_lr_twitch_start_date', sanitize_text_field($_POST['lr_twitch_start_date']));
            }
            if (isset($_POST['lr_twitch_end_date'])) {
                update_post_meta($post_id, '_lr_twitch_end_date', sanitize_text_field($_POST['lr_twitch_end_date']));
            }

            $this->clear_known_caches();
        }

    }

    /**
     * REGISTRAZIONE DELLE REST API
     */
    public function register_rest_endpoints()
    {
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

        // 4. GET Schedule
        register_rest_route($namespace, '/schedule', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_schedule'),
            'permission_callback' => '__return_true',
        ));

        // 5. GET Banner Stats (per reportistica esterna)
        register_rest_route($namespace, '/stats', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_stats'),
            'permission_callback' => '__return_true',
        ));

        // 6. GET Twitch Events
        register_rest_route($namespace, '/twitch-events', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_twitch_events'),
            'permission_callback' => '__return_true',
        ));
    }

    public function get_active_banner($request)
    {
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

        $fallback = $this->get_fallback_banner_response();
        if ($fallback) {
            return new WP_REST_Response($fallback, 200);
        }

        return new WP_REST_Response(array('message' => 'No active banner right now.'), 404);
    }

    private function get_fallback_banner_response()
    {
        $image_url = get_option('lr_app_banner_fallback_image_url', '');
        if (empty($image_url)) {
            return null;
        }

        $target_url = get_option('lr_app_banner_fallback_target_url', home_url('/'));
        if (empty($target_url)) {
            $target_url = home_url('/');
        }

        return array(
            'id' => 'fallback',
            'imageUrl' => esc_url_raw($image_url),
            'targetUrl' => esc_url_raw($target_url),
            'isFallback' => true,
        );
    }

    public function track_impression($request)
    {
        $params = $request->get_json_params();
        $banner_id = isset($params['bannerId']) ? intval($params['bannerId']) : 0;

        if ($banner_id <= 0) {
            $banner_id = intval($request->get_param('bannerId'));
        }

        if ($banner_id > 0 && get_post_type($banner_id) === 'lr_app_banner') {
            $current_impressions = intval(get_post_meta($banner_id, '_lr_banner_impressions', true));
            update_post_meta($banner_id, '_lr_banner_impressions', $current_impressions + 1);
            return new WP_REST_Response(array('success' => true), 200);
        }

        return new WP_REST_Response(array('success' => false, 'error' => 'Invalid banner ID or Post Type'), 400);
    }

    public function track_click($request)
    {
        $params = $request->get_json_params();
        $banner_id = isset($params['bannerId']) ? intval($params['bannerId']) : 0;

        if ($banner_id <= 0) {
            $banner_id = intval($request->get_param('bannerId'));
        }

        if ($banner_id > 0 && get_post_type($banner_id) === 'lr_app_banner') {
            $current_clicks = intval(get_post_meta($banner_id, '_lr_banner_clicks', true));
            update_post_meta($banner_id, '_lr_banner_clicks', $current_clicks + 1);
            return new WP_REST_Response(array('success' => true), 200);
        }

        return new WP_REST_Response(array('success' => false, 'error' => 'Invalid banner ID or Post Type'), 400);
    }

    public function get_schedule($request)
    {
        $args = array(
            'post_type' => 'portfolio',
            'post_status' => 'publish',
            'posts_per_page' => -1,
        );

        $query = new WP_Query($args);
        $schedule = array();

        if ($query->have_posts()) {
            foreach ($query->posts as $post) {
                // Utilizza get_field() di ACF se disponibile, sennò get_post_meta
                $subtitle = function_exists('get_field') ? get_field('app_schedule_subtitle', $post->ID) : get_post_meta($post->ID, 'app_schedule_subtitle', true);
                $day_raw = function_exists('get_field') ? get_field('app_schedule_day', $post->ID) : get_post_meta($post->ID, 'app_schedule_day', true);
                $start = function_exists('get_field') ? get_field('app_schedule_start_time', $post->ID) : get_post_meta($post->ID, 'app_schedule_start_time', true);
                $end = function_exists('get_field') ? get_field('app_schedule_end_time', $post->ID) : get_post_meta($post->ID, 'app_schedule_end_time', true);

                // Normalizza i giorni in un array in modo da supportare programmi multi-giorno
                $normalized_days = array();
                if (is_array($day_raw)) {
                    $normalized_days = $day_raw;
                } elseif (is_string($day_raw) && !empty($day_raw)) {
                    $try_unserialize = @unserialize($day_raw);
                    if ($try_unserialize !== false && is_array($try_unserialize)) {
                        $normalized_days = $try_unserialize;
                    } else {
                        $normalized_days = array_map('trim', explode(',', $day_raw));
                    }
                } elseif (is_numeric($day_raw)) {
                    $normalized_days = array((string) $day_raw);
                }

                // Tentativo 1: Campo Immagine ACF Custom
                $image = function_exists('get_field') ? get_field('app_schedule_image', $post->ID) : get_post_meta($post->ID, 'app_schedule_image', true);

                if (is_array($image) && isset($image['url'])) {
                    $image = $image['url'];
                } elseif (is_numeric($image)) {
                    $image_url_arr = wp_get_attachment_image_src($image, 'large');
                    $image = $image_url_arr ? $image_url_arr[0] : '';
                }

                // Tentativo 2: Recupero esplicito della SECOND FEATURED IMAGE (Multiple Post Thumbnails plugin / Meta Keys generiche)
                if (empty($image)) {
                    if (class_exists('MultiPostThumbnails')) {
                        $secondary_image = MultiPostThumbnails::get_post_thumbnail_url('portfolio', 'secondary-image', $post->ID, 'large');
                        if (!empty($secondary_image)) {
                            $image = $secondary_image;
                        }
                    }

                    if (empty($image)) {
                        $second_id = get_post_meta($post->ID, 'portfolio_secondary-image_thumbnail_id', true);
                        if (!$second_id) {
                            $second_id = get_post_meta($post->ID, 'dfi_image', true); // Dynamic Featured Image
                        }

                        if ($second_id && is_numeric($second_id)) {
                            $image_url_arr = wp_get_attachment_image_src($second_id, 'large');
                            $image = $image_url_arr ? $image_url_arr[0] : '';
                        } elseif (!empty($second_id) && is_string($second_id)) {
                            $image = $second_id;
                        }
                    }
                }

                // Fallback di Ultima Ratio: Post Thumbnail primario
                if (empty($image)) {
                    $image_id = get_post_thumbnail_id($post->ID);
                    if ($image_id) {
                        $image_url_arr = wp_get_attachment_image_src($image_id, 'large');
                        $image = $image_url_arr ? $image_url_arr[0] : '';
                    }
                }

                // Recupera il feed RSS Spreaker (opzionale)
                $rss_feed = function_exists('get_field') ? get_field('app_schedule_rss_feed', $post->ID) : get_post_meta($post->ID, 'app_schedule_rss_feed', true);

                // Recupera se trasmissione è podcast
                $is_podcast = function_exists('get_field') ? get_field('is_podcast', $post->ID) : get_post_meta($post->ID, 'is_podcast', true);

                // Recupera categoria podcast
                $podcast_category = function_exists('get_field') ? (get_field('podcast_category', $post->ID) ?: '') : (get_post_meta($post->ID, 'podcast_category', true) ?: '');

                // Aggiungilo all'app per ogni giorno di programmazione
                if (!empty($normalized_days) && !empty($start)) {
                    foreach ($normalized_days as $d) {
                        if (!empty($d)) {
                            $schedule[] = array(
                                'id' => (string) $post->ID . '_' . $d,
                                'postId' => (string) $post->ID,
                                'title' => html_entity_decode(get_the_title($post->ID)),
                                'subtitle' => $subtitle,
                                'day' => (string) $d,
                                'startTime' => $start,
                                'endTime' => $end,
                                'imageUrl' => $image ? $image : '',
                                'rssFeed' => !empty($rss_feed) ? $rss_feed : '',
                                'is_podcast' => (bool) $is_podcast,
                                'podcast_category' => $podcast_category,
                            );
                        }
                    }
                }
            }
            wp_reset_postdata();
        }

        return new WP_REST_Response($schedule, 200);
    }

    public function get_twitch_events($request)
    {
        $cached = get_transient('lr_app_twitch_events');
        if ($cached !== false) {
            return new WP_REST_Response($cached, 200);
        }

        $now_timestamp = current_time('timestamp');
        $now = date('Y-m-d\TH:i', $now_timestamp);
        $week_end = date('Y-m-d\TH:i', strtotime('+7 days', $now_timestamp));

        $args = array(
            'post_type' => 'lr_twitch_event',
            'post_status' => 'publish',
            'posts_per_page' => -1,
            'meta_key' => '_lr_twitch_start_date',
            'orderby' => 'meta_value',
            'order' => 'ASC',
            'meta_query' => array(
                'relation' => 'AND',
                array(
                    'key' => '_lr_twitch_start_date',
                    'value' => $week_end,
                    'compare' => '<=',
                    'type' => 'DATETIME'
                ),
                array(
                    'key' => '_lr_twitch_end_date',
                    'value' => $now,
                    'compare' => '>=',
                    'type' => 'DATETIME'
                )
            ),
        );

        $query = new WP_Query($args);
        $events = array();

        if ($query->have_posts()) {
            foreach ($query->posts as $post) {
                $image_id = get_post_thumbnail_id($post->ID);
                $image_url = $image_id ? wp_get_attachment_image_url($image_id, 'full') : '';
                $target_url = get_post_meta($post->ID, '_lr_twitch_target_url', true);
                $start_date = get_post_meta($post->ID, '_lr_twitch_start_date', true);
                $end_date = get_post_meta($post->ID, '_lr_twitch_end_date', true);

                if (empty($image_url) || empty($target_url) || empty($start_date) || empty($end_date)) {
                    continue;
                }

                $events[] = array(
                    'id' => (string) $post->ID,
                    'title' => html_entity_decode(get_the_title($post->ID)),
                    'imageUrl' => esc_url_raw($image_url),
                    'targetUrl' => esc_url_raw($target_url),
                    'startDate' => $start_date,
                    'endDate' => $end_date,
                );
            }
            wp_reset_postdata();
        }

        set_transient('lr_app_twitch_events', $events, 5 * MINUTE_IN_SECONDS);

        return new WP_REST_Response($events, 200);
    }

    /**
     * GET /wp-json/ladyapp/v1/stats
     *
     * Restituisce le statistiche aggregate (impressions e click) di tutti i banner,
     * sia attivi che scaduti. I contatori accumulati non vengono mai azzerati.
     */
    public function get_stats($request)
    {
        $args = array(
            'post_type' => 'lr_app_banner',
            'post_status' => array('publish', 'draft', 'private', 'trash'),
            'posts_per_page' => -1,
            'orderby' => 'date',
            'order' => 'DESC',
        );

        $query = new WP_Query($args);
        $banners = array();

        $total_impressions = 0;
        $total_clicks = 0;

        if ($query->have_posts()) {
            foreach ($query->posts as $post) {
                $impressions = intval(get_post_meta($post->ID, '_lr_banner_impressions', true));
                $clicks = intval(get_post_meta($post->ID, '_lr_banner_clicks', true));
                $ctr = $impressions > 0 ? round(($clicks / $impressions) * 100, 2) : 0.0;

                $total_impressions += $impressions;
                $total_clicks += $clicks;

                $banners[] = array(
                    'id' => $post->ID,
                    'title' => html_entity_decode(get_the_title($post->ID)),
                    'status' => $post->post_status,
                    'start_date' => get_post_meta($post->ID, '_lr_banner_start_date', true),
                    'end_date' => get_post_meta($post->ID, '_lr_banner_end_date', true),
                    'target_url' => get_post_meta($post->ID, '_lr_banner_target_url', true),
                    'impressions' => $impressions,
                    'clicks' => $clicks,
                    'ctr_percent' => $ctr,
                );
            }
            wp_reset_postdata();
        }

        $total_ctr = $total_impressions > 0 ? round(($total_clicks / $total_impressions) * 100, 2) : 0.0;

        $response = array(
            'generated_at' => gmdate('c'),
            'totals' => array(
                'impressions' => $total_impressions,
                'clicks' => $total_clicks,
                'ctr_percent' => $total_ctr,
            ),
            'banners' => $banners,
        );

        return new WP_REST_Response($response, 200);
    }
}

// Inizializza il plugin
register_activation_hook(__FILE__, array('LadyRadioAppBannersPlugin_183', 'activate'));
new LadyRadioAppBannersPlugin_183();
