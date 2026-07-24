-- Disable remaining business-workflow audit triggers
ALTER TABLE public.invitations DISABLE TRIGGER trg_audit_log_invitations;
ALTER TABLE public.licenses DISABLE TRIGGER trg_audit_log_licenses;
ALTER TABLE public.system_admins DISABLE TRIGGER trg_audit_log_system_admins;
