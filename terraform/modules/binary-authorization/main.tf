# Binary Authorization: cosign attestor + cluster admission policy for boutique-gke.

locals {
  cluster_admission_id = "${var.location}.${var.cluster_name}"
}

resource "google_container_analysis_note" "cosign" {
  project = var.project_id
  name    = "${replace(var.attestor_id, "-", "_")}_note"

  attestation_authority {
    hint {
      human_readable_name = var.attestor_description
    }
  }
}

resource "google_binary_authorization_attestor" "cosign" {
  project     = var.project_id
  name        = var.attestor_id
  description = var.attestor_description

  attestation_authority_note {
    note_reference = google_container_analysis_note.cosign.name

    public_keys {
      comment = "Cosign CI signing key"
      pkix_public_key {
        public_key_pem      = trimspace(var.cosign_public_key_pem)
        signature_algorithm = var.cosign_signature_algorithm
      }
    }
  }
}

resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  # GKE and Google-managed system images — exempt from cosign attestation.
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google_containers/*"
  }

  admission_whitelist_patterns {
    name_pattern = "gcr.io/gke-release/*"
  }

  admission_whitelist_patterns {
    name_pattern = "gcr.io/cloud-sql-connectors/*"
  }

  admission_whitelist_patterns {
    name_pattern = "gcr.io/config-management/*"
  }

  dynamic "admission_whitelist_patterns" {
    for_each = var.platform_image_whitelist_patterns
    content {
      name_pattern = admission_whitelist_patterns.value
    }
  }

  default_admission_rule {
    evaluation_mode  = "ALWAYS_ALLOW"
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
  }

  cluster_admission_rules {
    cluster                 = local.cluster_admission_id
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = var.enforcement_mode
    require_attestations_by = [google_binary_authorization_attestor.cosign.name]
  }
}
