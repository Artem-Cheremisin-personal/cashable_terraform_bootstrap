# This is a static, validated site.pp file.
# It uses an external fact $facts['role'] to classify nodes.

node default {
  notify { 'default_node_notification':
    message => "Node ${facts['fqdn']} is managed by Puppet but has no specific role.",
  }
}

node /.*/ {
  case $facts['role'] {
    'app': {
      notify { 'app_classification_notification':
        message => "Applying app_config to node ${facts['fqdn']} with role 'app'",
      }
      include ::app_config
    }
    'nginx': {
      notify { 'nginx_classification_notification':
        message => "Applying nginx_config to node ${facts['fqdn']} with role 'nginx'",
      }
      include ::nginx_config
    }
    default: {
      notify { 'unmatched_role_notification':
        message => "Node ${facts['fqdn']} has role '${facts['role']}', but no matching configuration was found.",
      }
    }
  }
}
