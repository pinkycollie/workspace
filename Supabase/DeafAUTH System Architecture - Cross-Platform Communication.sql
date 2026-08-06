-- DEAFAUTH VISUAL-FIRST ACCESSIBILITY SYSTEM
-- Visual authentication and accessibility preferences

-- =====================================================
-- DEAFAUTH VISUAL-FIRST CORE TABLES
-- =====================================================

-- Visual-first user preferences and accessibility settings
CREATE TABLE IF NOT EXISTS deafauth.user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  username text UNIQUE, -- User's chosen display name
  persist_id uuid NOT NULL, -- Persistent ID for cross-device sync (sibling devices)
  
  -- VISUAL-FIRST accessibility preferences
  visual_authentication jsonb, -- Visual patterns, colors, gestures for auth
  visual_indicators jsonb, -- Visual cues, alerts, notifications preferences
  sign_language_profile jsonb, -- ASL, BSL, etc. preferences and proficiency
  visual_contrast_settings jsonb, -- High contrast, color schemes, brightness
  text_display_preferences jsonb, -- Font size, spacing, visual text layout
  
  -- Visual communication modes (prioritized)
  communication_modes text[] DEFAULT ARRAY['visual', 'sign_language', 'text', 'captions'], 
  preferred_visual_layout text DEFAULT 'visual_first', -- Always visual-first
  
  -- Device visual capabilities
  device_preferences jsonb, -- Preferred visual input/output devices
  
  -- Cross-platform sync settings
  sync_across_devices boolean DEFAULT true,
  auto_connect_siblings boolean DEFAULT true, -- Connect to sibling devices automatically
  
  -- Privacy settings
  share_with_pinksync boolean DEFAULT true, -- Allow PinkSync to enhance visual experience
  anonymize_usage_data boolean DEFAULT false,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Visual-capable IoT device registry
CREATE TABLE IF NOT EXISTS deafauth.iot_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  persist_id uuid REFERENCES deafauth.user_preferences(persist_id),
  
  device_type text NOT NULL, -- 'browser', 'extension', 'visual_iot', 'mobile_app', 'desktop_app'
  device_id text NOT NULL, -- Unique device identifier
  device_name text, -- User-friendly name
  
  -- VISUAL-FIRST device capabilities
  visual_display_quality text DEFAULT 'standard', -- 'low', 'standard', 'high', '4k', 'hdr'
  can_show_visual_alerts boolean DEFAULT true, -- Primary accessibility feature
  supports_sign_language_input boolean DEFAULT false, -- Camera for ASL input
  supports_visual_authentication boolean DEFAULT true, -- Visual auth patterns
  can_display_captions boolean DEFAULT true,
  supports_visual_haptic_feedback boolean DEFAULT false, -- Visual + haptic combined
  
  -- Traditional capabilities (secondary)
  can_send_vibration boolean DEFAULT false,
  has_microphone boolean DEFAULT false,
  has_camera boolean DEFAULT false, -- For sign language input
  
  -- Communication settings
  cors_origin text, -- For browser/extension CORS settings
  websocket_endpoint text, -- For real-time visual communication
  api_key_hash text, -- Hashed API key for device authentication
  
  -- Status
  is_active boolean DEFAULT true,
  last_seen timestamptz DEFAULT now(),
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  UNIQUE(user_id, device_id)
);

-- Visual-first PinkSync sessions
CREATE TABLE IF NOT EXISTS deafauth.pinksync_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  persist_id uuid REFERENCES deafauth.user_preferences(persist_id),
  
  -- PinkSync node connection
  connected_node_id uuid, -- Which PinkSync visual accessibility node they're using
  tower_connection_id text, -- Which tower connection
  
  -- Session details
  session_token text NOT NULL, -- For secure communication
  communication_type text NOT NULL, -- 'visual_websocket', 'visual_cors_api', 'visual_iot_mqtt'
  
  -- VISUAL accessibility context
  current_visual_needs jsonb, -- What visual accessibility features are currently needed
  active_visual_services text[], -- What PinkSync visual services are currently active
  
  -- Session status
  is_active boolean DEFAULT true,
  started_at timestamptz DEFAULT now(),
  last_activity timestamptz DEFAULT now(),
  ended_at timestamptz
);

-- =====================================================
-- ENABLE RLS ON DEAFAUTH TABLES
-- =====================================================

ALTER TABLE deafauth.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE deafauth.iot_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE deafauth.pinksync_sessions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- DEAFAUTH RLS POLICIES - USER PRIVACY FIRST
-- =====================================================

-- Users control their own preferences completely
CREATE POLICY "Users manage own preferences" 
ON deafauth.user_preferences FOR ALL
TO authenticated 
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users control their own IoT devices
CREATE POLICY "Users manage own IoT devices" 
ON deafauth.iot_devices FOR ALL
TO authenticated 
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- PinkSync can see device capabilities for connected users (but not personal data)
CREATE POLICY "PinkSync sees device capabilities only" 
ON deafauth.iot_devices FOR SELECT
TO authenticated 
USING (
  user_id = auth.uid() -- Users see their own devices
  OR
  -- PinkSync nodes can see capabilities of users currently connected to them
  EXISTS (
    SELECT 1 FROM deafauth.pinksync_sessions ps
    WHERE ps.user_id = deafauth.iot_devices.user_id
    AND ps.is_active = true
    AND EXISTS (
      SELECT 1 FROM private.ecosystem_api_keys eak
      WHERE eak.user_id = auth.uid()
      AND eak.service_name = 'pinksync_mesh'
      AND eak.is_active = true
    )
  )
);

-- Users control their PinkSync sessions
CREATE POLICY "Users manage own PinkSync sessions" 
ON deafauth.pinksync_sessions FOR ALL
TO authenticated 
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- PinkSync nodes can see active sessions for users connected to them
CREATE POLICY "PinkSync nodes see connected sessions" 
ON deafauth.pinksync_sessions FOR SELECT
TO authenticated 
USING (
  user_id = auth.uid() -- Users see their own sessions
  OR
  -- PinkSync nodes see sessions connected to their nodes
  EXISTS (
    SELECT 1 FROM pinksync.mesh_nodes mn
    WHERE mn.id::text = deafauth.pinksync_sessions.connected_node_id::text
    AND mn.provider_id = auth.uid()
  )
);

-- =====================================================
-- FIBONROSE VISUAL TRUST VERIFICATION INTEGRATION
-- =====================================================

-- Visual trust verification table
CREATE TABLE IF NOT EXISTS fibonrose.visual_trust_verification (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  verification_type text NOT NULL, -- 'visual_pattern', 'sign_language_verification', 'visual_identity'
  
  -- Visual verification data
  visual_pattern_hash text, -- Hashed visual authentication pattern
  sign_language_sample bytea, -- Encrypted sign language verification video/image
  visual_identity_proof bytea, -- Visual proof of deaf/HOH community involvement
  
  -- Trust level achieved through visual verification
  trust_level text DEFAULT 'visual_basic',
  verification_status text DEFAULT 'pending',
  
  -- Community validation (visual-first)
  validated_by_community boolean DEFAULT false,
  visual_community_endorsements integer DEFAULT 0,
  
  verified_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on Fibonrose visual trust
ALTER TABLE fibonrose.visual_trust_verification ENABLE ROW LEVEL SECURITY;

-- Users control their own visual trust verification
CREATE POLICY "Users manage own visual trust verification" 
ON fibonrose.visual_trust_verification FOR ALL
TO authenticated 
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Community validators can view for verification (visual-first process)
CREATE POLICY "Visual community validators access verification" 
ON fibonrose.visual_trust_verification FOR SELECT
TO authenticated 
USING (
  user_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM fibonrose.trust_profiles tp
    WHERE tp.user_id = auth.uid()
    AND tp.can_validate_visual_trust = true
    AND tp.is_visual_community_validator = true
  )
);

-- =====================================================
-- UPDATED DEAFAUTH VISUAL FUNCTIONS
-- =====================================================

-- Function to establish visual-first PinkSync communication
CREATE OR REPLACE FUNCTION deafauth.establish_visual_pinksync_connection(
  p_user_id uuid,
  p_node_id uuid,
  p_communication_type text,
  p_visual_needs jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'deafauth, public'
AS $$
DECLARE
  v_session_id uuid;
  v_persist_id uuid;
  v_session_token text;
BEGIN
  -- Get user's persist_id
  SELECT persist_id INTO v_persist_id 
  FROM deafauth.user_preferences 
  WHERE user_id = p_user_id;
  
  -- Generate secure session token
  v_session_token := encode(gen_random_bytes(32), 'base64');
  
  -- Create visual-first session
  INSERT INTO deafauth.pinksync_sessions (
    user_id, persist_id, connected_node_id, session_token,
    communication_type, current_visual_needs, active_visual_services
  ) VALUES (
    p_user_id, v_persist_id, p_node_id, v_session_token,
    p_communication_type, p_visual_needs, ARRAY['visual_accessibility']::text[]
  ) RETURNING id INTO v_session_id;
  
  RETURN v_session_id;
END;
$$;

-- Function to sync visual preferences across sibling devices
CREATE OR REPLACE FUNCTION deafauth.sync_visual_preferences(
  p_user_id uuid,
  p_visual_updates jsonb
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'deafauth, public'
AS $$
DECLARE
  v_persist_id uuid;
BEGIN
  -- Get user's persist_id
  SELECT persist_id INTO v_persist_id 
  FROM deafauth.user_preferences 
  WHERE user_id = p_user_id;
  
  -- Update visual-first preferences for user
  UPDATE deafauth.user_preferences 
  SET 
    visual_authentication = COALESCE(p_visual_updates->'visual_authentication', visual_authentication),
    visual_indicators = COALESCE(p_visual_updates->'visual_indicators', visual_indicators),
    sign_language_profile = COALESCE(p_visual_updates->'sign_language_profile', sign_language_profile),
    visual_contrast_settings = COALESCE(p_visual_updates->'visual_contrast_settings', visual_contrast_settings),
    text_display_preferences = COALESCE(p_visual_updates->'text_display_preferences', text_display_preferences),
    updated_at = now()
  WHERE user_id = p_user_id;
  
  -- Notify all active sibling devices about visual preference changes
  PERFORM pg_notify('deafauth_visual_sync_' || v_persist_id::text, p_visual_updates::text);
  
  RETURN true;
END;
$$;

-- Function to register IoT device
CREATE OR REPLACE FUNCTION deafauth.register_iot_device(
  p_user_id uuid,
  p_device_type text,
  p_device_id text,
  p_device_name text,
  p_capabilities jsonb,
  p_cors_origin text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'deafauth, public'
AS $$
DECLARE
  v_persist_id uuid;
  v_device_uuid uuid;
  v_api_key_hash text;
BEGIN
  -- Get user's persist_id
  SELECT persist_id INTO v_persist_id 
  FROM deafauth.user_preferences 
  WHERE user_id = p_user_id;
  
  -- Generate API key hash for device authentication
  v_api_key_hash := encode(digest(gen_random_bytes(32)::text, 'sha256'), 'hex');
  
  -- Register or update device
  INSERT INTO deafauth.iot_devices (
    user_id, persist_id, device_type, device_id, device_name,
    can_send_vibration, can_show_visual_alerts, has_microphone, 
    has_camera, has_haptic_feedback, cors_origin, api_key_hash
  ) VALUES (
    p_user_id, v_persist_id, p_device_type, p_device_id, p_device_name,
    COALESCE((p_capabilities->>'can_send_vibration')::boolean, false),
    COALESCE((p_capabilities->>'can_show_visual_alerts')::boolean, true),
    COALESCE((p_capabilities->>'has_microphone')::boolean, false),
    COALESCE((p_capabilities->>'has_camera')::boolean, false),
    COALESCE((p_capabilities->>'has_haptic_feedback')::boolean, false),
    p_cors_origin, v_api_key_hash
  )
  ON CONFLICT (user_id, device_id) 
  DO UPDATE SET 
    device_name = EXCLUDED.device_name,
    can_send_vibration = EXCLUDED.can_send_vibration,
    can_show_visual_alerts = EXCLUDED.can_show_visual_alerts,
    has_microphone = EXCLUDED.has_microphone,
    has_camera = EXCLUDED.has_camera,
    has_haptic_feedback = EXCLUDED.has_haptic_feedback,
    cors_origin = EXCLUDED.cors_origin,
    last_seen = now(),
    is_active = true
  RETURNING id INTO v_device_uuid;
  
  RETURN v_device_uuid;
END;
$$;

-- =====================================================
-- CORS AND COMMUNICATION SETUP
-- =====================================================

-- View for browser extension communication
CREATE OR REPLACE VIEW deafauth.extension_bridge AS
SELECT 
  up.user_id,
  up.username,
  up.persist_id,
  up.hearing_profile,
  up.visual_preferences,
  up.communication_modes,
  iot.cors_origin,
  iot.device_name,
  ps.session_token,
  ps.connected_node_id,
  ps.active_services
FROM deafauth.user_preferences up
JOIN deafauth.iot_devices iot ON up.persist_id = iot.persist_id
LEFT JOIN deafauth.pinksync_sessions ps ON up.persist_id = ps.persist_id AND ps.is_active = true
WHERE iot.device_type IN ('browser', 'extension')
  AND iot.is_active = true
  AND up.user_id = auth.uid();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_deafauth_preferences_persist_id ON deafauth.user_preferences(persist_id);
CREATE INDEX IF NOT EXISTS idx_deafauth_devices_persist_id ON deafauth.iot_devices(persist_id);
CREATE INDEX IF NOT EXISTS idx_deafauth_sessions_persist_id ON deafauth.pinksync_sessions(persist_id);
CREATE INDEX IF NOT EXISTS idx_deafauth_sessions_active ON deafauth.pinksync_sessions(is_active, last_activity);