-- ================================================
-- MBTQ UNIVERSE: LifecycleBlueprint Database Schema
-- ================================================
-- Purpose: Store AI-powered agentic workflows for Deaf-first entrepreneurship
-- Architecture: Modular, versioned, auditable
-- Integration: DeafAUTH, Fibonrose, PinkSync, 360Magicians

-- ================================================
-- 1. PROJECTS TABLE
-- ================================================
-- One row per entrepreneur/business intake
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Identity (linked to DeafAUTH)
  owner_id UUID NOT NULL, -- DeafAUTH user ID
  owner_name TEXT NOT NULL,
  owner_email TEXT,
  
  -- Business basics
  business_name TEXT NOT NULL,
  business_type TEXT, -- e.g., "bakery", "tech startup", "consulting"
  location_state TEXT,
  location_city TEXT,
  
  -- Current lifecycle status
  current_phase TEXT NOT NULL DEFAULT 'idea', 
  -- 'idea' | 'build' | 'grow' | 'managed'
  
  phase_started_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Metadata
  tags TEXT[], -- ["deaf-owned", "women-owned", "veteran-owned"]
  source TEXT, -- "web_intake", "360magicians_referral", "community"
  
  -- Trust & reputation (Fibonrose integration)
  fibonrose_score DECIMAL(5,2), -- 0.00 to 100.00
  fibonrose_badges JSONB, -- {"badges": ["pioneer", "compliant", "funded"]}
  
  -- Flags
  is_active BOOLEAN DEFAULT TRUE,
  is_archived BOOLEAN DEFAULT FALSE
);

-- Indexes for performance
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_phase ON projects(current_phase);
CREATE INDEX idx_projects_active ON projects(is_active, is_archived);

-- ================================================
-- 2. LIFECYCLE_PHASES TABLE
-- ================================================
-- Tracks phase transitions and history
CREATE TABLE lifecycle_phases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  
  phase_name TEXT NOT NULL, -- 'idea' | 'build' | 'grow' | 'managed'
  entered_at TIMESTAMPTZ DEFAULT NOW(),
  exited_at TIMESTAMPTZ,
  
  -- Decision point that triggered this phase
  triggered_by TEXT, -- e.g., "validation_pass", "funding_secured"
  trigger_details JSONB,
  
  -- Agent activity summary
  agents_executed TEXT[], -- ["IntakeAgent", "ValidatorAgent"]
  total_agent_runs INT DEFAULT 0,
  
  -- Status
  status TEXT DEFAULT 'active', -- 'active' | 'completed' | 'blocked'
  blocked_reason TEXT
);

CREATE INDEX idx_phases_project ON lifecycle_phases(project_id);
CREATE INDEX idx_phases_active ON lifecycle_phases(status);

-- ================================================
-- 3. AGENT_RUNS TABLE
-- ================================================
-- Logs every agent execution with inputs/outputs
CREATE TABLE agent_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  phase_id UUID REFERENCES lifecycle_phases(id) ON DELETE SET NULL,
  
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Agent identity
  agent_name TEXT NOT NULL, -- "IntakeAgent", "ValidatorAgent", etc.
  agent_role TEXT, -- "research", "validation", "compliance", "funding"
  
  -- Execution details
  inputs JSONB, -- What data the agent received
  outputs JSONB, -- What the agent produced
  sources TEXT[], -- ["SBA", "Workforce", "VR", "PinkSync"]
  
  -- Performance metrics
  duration_ms INT, -- How long it took
  tokens_used INT, -- For LLM agents
  
  -- Status
  status TEXT NOT NULL DEFAULT 'success', 
  -- 'success' | 'failure' | 'partial' | 'timeout'
  error_message TEXT,
  
  -- Routing
  next_action TEXT, -- "advance_to_build", "escalate_to_360magicians"
  next_action_reason TEXT
);

CREATE INDEX idx_agent_runs_project ON agent_runs(project_id);
CREATE INDEX idx_agent_runs_phase ON agent_runs(phase_id);
CREATE INDEX idx_agent_runs_agent ON agent_runs(agent_name);
CREATE INDEX idx_agent_runs_status ON agent_runs(status);

-- ================================================
-- 4. ARTIFACTS TABLE
-- ================================================
-- Stores JSON outputs from agents (versioned)
CREATE TABLE artifacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  agent_run_id UUID REFERENCES agent_runs(id) ON DELETE SET NULL,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Artifact identity
  artifact_type TEXT NOT NULL, 
  -- "idea.json", "validation.json", "builder.json", "proposal_packet"
  artifact_name TEXT NOT NULL,
  
  -- Content
  content JSONB NOT NULL, -- The actual JSON artifact
  
  -- Versioning
  version INT NOT NULL DEFAULT 1,
  is_latest BOOLEAN DEFAULT TRUE,
  supersedes UUID REFERENCES artifacts(id), -- Previous version
  
  -- Metadata
  file_size_bytes INT,
  checksum TEXT, -- For integrity validation
  
  -- Access control
  visibility TEXT DEFAULT 'owner', -- 'owner' | 'team' | 'public'
  expires_at TIMESTAMPTZ -- For temporary artifacts
);

CREATE INDEX idx_artifacts_project ON artifacts(project_id);
CREATE INDEX idx_artifacts_type ON artifacts(artifact_type);
CREATE INDEX idx_artifacts_latest ON artifacts(is_latest);

-- ================================================
-- 5. DECISION_LOGS TABLE
-- ================================================
-- Tracks decision_points and routing logic
CREATE TABLE decision_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  phase_id UUID REFERENCES lifecycle_phases(id) ON DELETE SET NULL,
  agent_run_id UUID REFERENCES agent_runs(id) ON DELETE SET NULL,
  
  decided_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Decision details
  decision_point TEXT NOT NULL, -- "validation_check", "funding_threshold"
  trigger_condition TEXT NOT NULL, -- "validation_pass", "score > 80"
  
  -- Evaluation
  condition_met BOOLEAN NOT NULL,
  evaluation_data JSONB, -- Data used to make decision
  
  -- Outcome
  action_taken TEXT NOT NULL, -- "advance_to_build", "route_to_360magicians"
  previous_phase TEXT,
  next_phase TEXT,
  
  -- Reasoning (for audit trail)
  reasoning TEXT,
  confidence_score DECIMAL(5,2) -- 0.00 to 100.00
);

CREATE INDEX idx_decision_logs_project ON decision_logs(project_id);
CREATE INDEX idx_decision_logs_phase ON decision_logs(phase_id);

-- ================================================
-- 6. COMPLIANCE_SCANS TABLE
-- ================================================
-- PinkSync integration: accessibility + regulatory checks
CREATE TABLE compliance_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  
  scanned_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Scan type
  scan_type TEXT NOT NULL, -- "accessibility", "sba_compliance", "workforce_rules"
  source TEXT NOT NULL, -- "PinkSync", "SBA API", "VR API"
  
  -- Results
  passed BOOLEAN NOT NULL,
  score DECIMAL(5,2),
  issues_found JSONB, -- Array of issues with severity levels
  
  -- Recommendations
  recommendations JSONB,
  auto_fixable BOOLEAN DEFAULT FALSE,
  
  -- Next scan
  next_scan_at TIMESTAMPTZ
);

CREATE INDEX idx_compliance_project ON compliance_scans(project_id);
CREATE INDEX idx_compliance_type ON compliance_scans(scan_type);
CREATE INDEX idx_compliance_passed ON compliance_scans(passed);

-- ================================================
-- 7. MAGICIAN_ESCALATIONS TABLE
-- ================================================
-- When projects need human-in-loop from 360Magicians
CREATE TABLE magician_escalations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  agent_run_id UUID REFERENCES agent_runs(id),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  
  -- Escalation details
  reason TEXT NOT NULL, -- "validation_failed", "complex_decision", "compliance_block"
  urgency TEXT NOT NULL DEFAULT 'medium', -- 'low' | 'medium' | 'high' | 'critical'
  
  context JSONB, -- Full context for magician to review
  
  -- Assignment
  assigned_to UUID, -- 360Magicians user ID
  assigned_at TIMESTAMPTZ,
  
  -- Resolution
  status TEXT DEFAULT 'open', -- 'open' | 'in_progress' | 'resolved' | 'escalated_further'
  resolution JSONB, -- Magician's decision/action
  resolution_notes TEXT
);

CREATE INDEX idx_escalations_project ON magician_escalations(project_id);
CREATE INDEX idx_escalations_status ON magician_escalations(status);
CREATE INDEX idx_escalations_urgency ON magician_escalations(urgency);

-- ================================================
-- 8. VIEWS FOR COMMON QUERIES
-- ================================================

-- Active projects dashboard
CREATE VIEW active_projects_dashboard AS
SELECT 
  p.id,
  p.business_name,
  p.owner_name,
  p.current_phase,
  p.fibonrose_score,
  lp.entered_at AS phase_started,
  COUNT(DISTINCT ar.id) AS total_agent_runs,
  COUNT(DISTINCT a.id) AS total_artifacts,
  MAX(cs.scanned_at) AS last_compliance_scan
FROM projects p
LEFT JOIN lifecycle_phases lp ON p.id = lp.project_id AND lp.status = 'active'
LEFT JOIN agent_runs ar ON p.id = ar.project_id
LEFT JOIN artifacts a ON p.id = a.project_id AND a.is_latest = TRUE
LEFT JOIN compliance_scans cs ON p.id = cs.project_id
WHERE p.is_active = TRUE AND p.is_archived = FALSE
GROUP BY p.id, p.business_name, p.owner_name, p.current_phase, p.fibonrose_score, lp.entered_at;

-- Agent performance metrics
CREATE VIEW agent_performance AS
SELECT 
  agent_name,
  agent_role,
  COUNT(*) AS total_runs,
  AVG(duration_ms) AS avg_duration_ms,
  SUM(tokens_used) AS total_tokens,
  COUNT(*) FILTER (WHERE status = 'success') AS successful_runs,
  COUNT(*) FILTER (WHERE status = 'failure') AS failed_runs,
  ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'success') / COUNT(*), 2) AS success_rate
FROM agent_runs
GROUP BY agent_name, agent_role
ORDER BY total_runs DESC;

-- ================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================
-- Enable RLS on all tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE lifecycle_phases ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE decision_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE magician_escalations ENABLE ROW LEVEL SECURITY;

-- Example policy: Users can only see their own projects
CREATE POLICY "Users can view own projects" ON projects
  FOR SELECT USING (auth.uid() = owner_id);

-- Example policy: 360Magicians can see all projects
CREATE POLICY "Magicians can view all projects" ON projects
  FOR SELECT USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = '360magician'
    OR
    (auth.jwt() -> 'app_metadata' ->> 'role') = '360magician'
  );

-- ================================================
-- 10. TRIGGERS FOR AUTOMATION
-- ================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-archive old artifact versions
CREATE OR REPLACE FUNCTION archive_old_artifact_versions()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_latest = TRUE THEN
    UPDATE artifacts 
    SET is_latest = FALSE 
    WHERE project_id = NEW.project_id 
      AND artifact_type = NEW.artifact_type 
      AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

CREATE TRIGGER artifact_version_control
  AFTER INSERT ON artifacts
  FOR EACH ROW EXECUTE FUNCTION archive_old_artifact_versions();

-- ================================================
-- NOTES FOR MBTQ:
-- ================================================
-- 1. Deploy this to Supabase via SQL Editor
-- 2. Create a user_roles table for 360Magicians permissions
-- 3. Use Supabase Auto API for instant REST/GraphQL endpoints
-- 4. Connect PinkSync webhooks to compliance_scans table
-- 5. Integrate DeafAUTH user IDs with owner_id field
-- 6. Set up Fibonrose to update fibonrose_score via API
-- 7. Use Supabase Realtime for live dashboard updates
-- ================================================