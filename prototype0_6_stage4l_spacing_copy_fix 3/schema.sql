PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS users (user_id TEXT PRIMARY KEY,display_name TEXT NOT NULL,login_identifier TEXT UNIQUE NOT NULL,role TEXT NOT NULL CHECK(role IN ('learner','instructor','admin','researcher')),account_status TEXT NOT NULL DEFAULT 'active',created_at TEXT NOT NULL,updated_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS learners (learner_id TEXT PRIMARY KEY,user_id TEXT UNIQUE NOT NULL REFERENCES users(user_id),learner_id_pseudo TEXT UNIQUE NOT NULL,onboarding_complete INTEGER NOT NULL DEFAULT 0,active_status TEXT NOT NULL DEFAULT 'active',created_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS instructors (instructor_id TEXT PRIMARY KEY,user_id TEXT UNIQUE NOT NULL REFERENCES users(user_id),active_status TEXT NOT NULL DEFAULT 'active');
CREATE TABLE IF NOT EXISTS courses (course_id TEXT PRIMARY KEY,course_code TEXT UNIQUE NOT NULL,course_title TEXT NOT NULL,description TEXT,status TEXT NOT NULL DEFAULT 'active');
CREATE TABLE IF NOT EXISTS course_versions (course_version_id TEXT PRIMARY KEY,course_id TEXT NOT NULL REFERENCES courses(course_id),version_number TEXT NOT NULL,effective_from TEXT NOT NULL,effective_to TEXT,status TEXT NOT NULL DEFAULT 'active');
CREATE TABLE IF NOT EXISTS sections (section_id TEXT PRIMARY KEY,course_version_id TEXT NOT NULL REFERENCES course_versions(course_version_id),section_code TEXT NOT NULL,academic_term TEXT NOT NULL,primary_instructor_id TEXT NOT NULL REFERENCES instructors(instructor_id),status TEXT NOT NULL DEFAULT 'active');
CREATE TABLE IF NOT EXISTS enrollments (enrollment_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),section_id TEXT NOT NULL REFERENCES sections(section_id),enrollment_status TEXT NOT NULL DEFAULT 'active',enrolled_at TEXT NOT NULL,UNIQUE(learner_id,section_id));
CREATE TABLE IF NOT EXISTS learning_outcomes (learning_outcome_id TEXT PRIMARY KEY,course_version_id TEXT NOT NULL REFERENCES course_versions(course_version_id),outcome_code TEXT NOT NULL,outcome_text TEXT NOT NULL,action_verb TEXT NOT NULL,active_status TEXT NOT NULL DEFAULT 'active');
CREATE TABLE IF NOT EXISTS concepts (concept_id TEXT PRIMARY KEY,concept_name TEXT NOT NULL,description TEXT,parent_concept_id TEXT REFERENCES concepts(concept_id));
CREATE TABLE IF NOT EXISTS concept_outcome_map (concept_id TEXT NOT NULL REFERENCES concepts(concept_id),learning_outcome_id TEXT NOT NULL REFERENCES learning_outcomes(learning_outcome_id),relationship_type TEXT NOT NULL DEFAULT 'supports',PRIMARY KEY(concept_id,learning_outcome_id));
CREATE TABLE IF NOT EXISTS content (content_id TEXT PRIMARY KEY,content_type TEXT NOT NULL,title TEXT NOT NULL,course_id TEXT REFERENCES courses(course_id),source_type TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'active');
CREATE TABLE IF NOT EXISTS content_versions (content_version_id TEXT PRIMARY KEY,content_id TEXT NOT NULL REFERENCES content(content_id),version_number TEXT NOT NULL,content_payload TEXT NOT NULL,provenance_type TEXT NOT NULL,qa_status TEXT NOT NULL,accessibility_status TEXT NOT NULL,created_at TEXT NOT NULL,effective_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS activities (activity_id TEXT PRIMARY KEY,course_version_id TEXT NOT NULL REFERENCES course_versions(course_version_id),week_number INTEGER NOT NULL,activity_type TEXT NOT NULL,content_version_id TEXT NOT NULL REFERENCES content_versions(content_version_id),activity_order INTEGER NOT NULL,requirement_level TEXT NOT NULL CHECK(requirement_level IN ('required','recommended','optional')),completion_rule TEXT NOT NULL,prerequisite_rule TEXT,status TEXT NOT NULL DEFAULT 'active');
CREATE TABLE IF NOT EXISTS learning_stacks (stack_id TEXT PRIMARY KEY,activity_id TEXT UNIQUE NOT NULL REFERENCES activities(activity_id),panel_count INTEGER NOT NULL,completion_rule TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS learning_stack_panels (panel_id TEXT PRIMARY KEY,stack_id TEXT NOT NULL REFERENCES learning_stacks(stack_id),panel_order INTEGER NOT NULL,panel_type TEXT NOT NULL,panel_payload TEXT NOT NULL,interaction_required INTEGER NOT NULL DEFAULT 0,UNIQUE(stack_id,panel_order));
CREATE TABLE IF NOT EXISTS quick_checks (quick_check_id TEXT PRIMARY KEY,activity_id TEXT UNIQUE NOT NULL REFERENCES activities(activity_id),title TEXT NOT NULL,estimated_minutes INTEGER NOT NULL,offer_policy TEXT NOT NULL,completion_rule TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS question_items (question_id TEXT PRIMARY KEY,question_version TEXT NOT NULL,question_type TEXT NOT NULL,prompt TEXT NOT NULL,stimulus_payload TEXT,response_options TEXT,expected_response TEXT,feedback_correct TEXT,feedback_incorrect TEXT,concept_id TEXT REFERENCES concepts(concept_id),learning_outcome_id TEXT REFERENCES learning_outcomes(learning_outcome_id),qa_status TEXT NOT NULL DEFAULT 'approved');
CREATE TABLE IF NOT EXISTS quick_check_questions (quick_check_id TEXT NOT NULL REFERENCES quick_checks(quick_check_id),question_id TEXT NOT NULL REFERENCES question_items(question_id),question_order INTEGER NOT NULL,required INTEGER NOT NULL DEFAULT 1,PRIMARY KEY(quick_check_id,question_id));
CREATE TABLE IF NOT EXISTS sessions (session_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),started_at TEXT NOT NULL,ended_at TEXT,device_id_pseudo TEXT,app_version TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS journeys (journey_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),course_id TEXT NOT NULL REFERENCES courses(course_id),section_id TEXT NOT NULL REFERENCES sections(section_id),course_version_id TEXT NOT NULL REFERENCES course_versions(course_version_id),week_number INTEGER NOT NULL,journey_state TEXT NOT NULL CHECK(journey_state IN ('not_started','in_progress','paused','completed')),current_activity_instance_id TEXT,started_at TEXT NOT NULL,last_activity_at TEXT NOT NULL,completed_at TEXT);
CREATE TABLE IF NOT EXISTS activity_instances (activity_instance_id TEXT PRIMARY KEY,activity_id TEXT NOT NULL REFERENCES activities(activity_id),learner_id TEXT NOT NULL REFERENCES learners(learner_id),journey_id TEXT NOT NULL REFERENCES journeys(journey_id),attempt_number INTEGER NOT NULL DEFAULT 1,activity_state TEXT NOT NULL CHECK(activity_state IN ('available','started','in_progress','completed','declined','skipped')),started_at TEXT,last_activity_at TEXT,completed_at TEXT,UNIQUE(activity_id,learner_id,journey_id,attempt_number));
CREATE TABLE IF NOT EXISTS stack_progress (activity_instance_id TEXT PRIMARY KEY REFERENCES activity_instances(activity_instance_id),current_panel_id TEXT REFERENCES learning_stack_panels(panel_id),panels_viewed TEXT NOT NULL DEFAULT '[]',panel_responses TEXT NOT NULL DEFAULT '{}',last_updated_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS quick_check_attempts (quick_check_attempt_id TEXT PRIMARY KEY,quick_check_id TEXT NOT NULL REFERENCES quick_checks(quick_check_id),activity_instance_id TEXT NOT NULL REFERENCES activity_instances(activity_instance_id),learner_id TEXT NOT NULL REFERENCES learners(learner_id),attempt_state TEXT NOT NULL CHECK(attempt_state IN ('offered','accepted','declined','in_progress','completed')),offered_at TEXT,accepted_at TEXT,declined_at TEXT,started_at TEXT,completed_at TEXT);
CREATE TABLE IF NOT EXISTS response_attempts (response_attempt_id TEXT PRIMARY KEY,question_id TEXT NOT NULL REFERENCES question_items(question_id),quick_check_attempt_id TEXT NOT NULL REFERENCES quick_check_attempts(quick_check_attempt_id),activity_instance_id TEXT NOT NULL REFERENCES activity_instances(activity_instance_id),learner_id TEXT NOT NULL REFERENCES learners(learner_id),response_value TEXT,correctness INTEGER,attempt_number INTEGER NOT NULL DEFAULT 1,started_at TEXT,submitted_at TEXT,response_time_ms INTEGER,feedback_presented INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS writing_drafts (writing_draft_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),activity_instance_id TEXT UNIQUE NOT NULL REFERENCES activity_instances(activity_instance_id),course_id TEXT NOT NULL REFERENCES courses(course_id),section_id TEXT NOT NULL REFERENCES sections(section_id),assignment_context TEXT NOT NULL,current_version_id TEXT,draft_status TEXT NOT NULL CHECK(draft_status IN ('draft','submitted','completed')),created_at TEXT NOT NULL,updated_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS writing_versions (writing_version_id TEXT PRIMARY KEY,writing_draft_id TEXT NOT NULL REFERENCES writing_drafts(writing_draft_id),version_number INTEGER NOT NULL,text_content TEXT NOT NULL,source_mode TEXT NOT NULL,word_count INTEGER NOT NULL,version_status TEXT NOT NULL CHECK(version_status IN ('draft','submitted','final')),created_at TEXT NOT NULL,submitted_at TEXT,UNIQUE(writing_draft_id,version_number));
CREATE TABLE IF NOT EXISTS feedback (feedback_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),target_type TEXT NOT NULL,target_id TEXT NOT NULL,feedback_source_type TEXT NOT NULL,feedback_category TEXT NOT NULL,feedback_text TEXT NOT NULL,created_at TEXT NOT NULL,viewed_at TEXT,saved_by_learner INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS reflection_responses (reflection_response_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),activity_instance_id TEXT NOT NULL REFERENCES activity_instances(activity_instance_id),prompt_id TEXT NOT NULL,response_mode TEXT NOT NULL,response_text TEXT,confidence_level TEXT,created_at TEXT NOT NULL,UNIQUE(activity_instance_id,prompt_id));
CREATE TABLE IF NOT EXISTS saved_items (saved_item_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),target_type TEXT NOT NULL,target_id TEXT NOT NULL,saved_at TEXT NOT NULL,removed_at TEXT,offline_available INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS learner_progress (learner_progress_id TEXT PRIMARY KEY,learner_id TEXT NOT NULL REFERENCES learners(learner_id),course_id TEXT NOT NULL REFERENCES courses(course_id),section_id TEXT NOT NULL REFERENCES sections(section_id),week_number INTEGER NOT NULL,progress_state TEXT NOT NULL CHECK(progress_state IN ('not_started','in_progress','completed')),required_completed_count INTEGER NOT NULL DEFAULT 0,required_total_count INTEGER NOT NULL DEFAULT 0,updated_at TEXT NOT NULL,UNIQUE(learner_id,section_id,week_number));
CREATE TABLE IF NOT EXISTS events (event_id TEXT PRIMARY KEY,event_name TEXT NOT NULL,event_schema_version TEXT NOT NULL,timestamp_utc_original TEXT NOT NULL,server_received_at TEXT NOT NULL,learner_id_pseudo TEXT NOT NULL,session_id TEXT,journey_id TEXT,activity_instance_id TEXT,sequence_number INTEGER NOT NULL,event_source TEXT NOT NULL,app_version TEXT NOT NULL,parent_event_id TEXT,previous_event_id TEXT,root_event_id TEXT,payload TEXT NOT NULL DEFAULT '{}');
CREATE INDEX IF NOT EXISTS idx_events_journey_seq ON events(journey_id,sequence_number);
CREATE INDEX IF NOT EXISTS idx_activity_instances_journey ON activity_instances(journey_id);
CREATE INDEX IF NOT EXISTS idx_journeys_learner_week ON journeys(learner_id,section_id,week_number,journey_state);
CREATE INDEX IF NOT EXISTS idx_saved_items_learner ON saved_items(learner_id,removed_at);
CREATE INDEX IF NOT EXISTS idx_writing_versions_draft ON writing_versions(writing_draft_id,version_number);

CREATE TABLE IF NOT EXISTS support_paths (
  support_path_id TEXT PRIMARY KEY,
  learner_id TEXT NOT NULL REFERENCES learners(learner_id),
  journey_id TEXT NOT NULL REFERENCES journeys(journey_id),
  originating_activity_instance_id TEXT NOT NULL REFERENCES activity_instances(activity_instance_id),
  concept_id TEXT REFERENCES concepts(concept_id),
  trigger_type TEXT NOT NULL,
  support_state TEXT NOT NULL CHECK(support_state IN ('active','resolved','escalated','saved_for_later')),
  current_step INTEGER NOT NULL DEFAULT 1,
  started_at TEXT NOT NULL,
  resolved_at TEXT,
  resolution_type TEXT
);
CREATE TABLE IF NOT EXISTS support_units (
  support_unit_id TEXT PRIMARY KEY,
  support_path_id TEXT NOT NULL REFERENCES support_paths(support_path_id),
  unit_order INTEGER NOT NULL,
  support_type TEXT NOT NULL,
  content_payload TEXT NOT NULL,
  provenance_type TEXT NOT NULL,
  qa_status TEXT NOT NULL,
  presented_at TEXT,
  completed_at TEXT,
  learner_response TEXT,
  UNIQUE(support_path_id,unit_order)
);
CREATE TABLE IF NOT EXISTS learning_gaps (
  learning_gap_id TEXT PRIMARY KEY,
  learner_id TEXT NOT NULL REFERENCES learners(learner_id),
  concept_id TEXT NOT NULL REFERENCES concepts(concept_id),
  gap_type TEXT NOT NULL,
  evidence_ids TEXT NOT NULL DEFAULT '[]',
  confidence REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL CHECK(status IN ('suspected','active','improving','resolved')),
  detected_at TEXT NOT NULL,
  resolved_at TEXT,
  resolution_evidence TEXT
);
