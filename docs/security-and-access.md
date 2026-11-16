# Security and access

[← Documentation index](README.md)

This section lists the controls the project provides and the ones that live outside it.

## Controls in the Ansible project

| Control             | How it works                                                                                                                                    |
|---------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| Secrets             | Passwords are in secrets.yml, encrypted with Ansible Vault. Playbooks ask for \<VAULT_PASSWORD\> or read a password file                        |
| SSH trust           | common creates the keys the NameNodes need for fencing. The generated private key stays in .generated/ssh/ and is excluded from version control |
| Web TLS             | HDFS web interfaces use HTTPS when hadoop_ssl_enabled is true                                                                                   |
| Firewall            | manage_firewall: true opens only the ports each node needs. It is off by default                                                                |
| Service accounts    | Each service runs as its own account (hadoop, kafka, zeppelin), not as root                                                                     |
| Destructive actions | Need an explicit flag and confirm_destroy_data=yes                                                                                              |

## Controls outside the project

- **Grafana sign-in** uses OpenID Connect against Keycloak at sso.example.corp, realm \<REALM\>, with PKCE. Members of the group grafana-admins become Grafana administrators and everyone else is a Viewer. Self-registration is off. The full set-up, including logout and the local fallback account, is in the SSO guide.

- **Zeppelin and Ranger** sign in through the Knox gateway and Keycloak, also described in the SSO guide.

- **Metrics ports** are open only to the monitoring node on Zeppelin. Do the same on every other node with manage_firewall.

- **Prometheus to Kubernetes** uses a service-account token from \<K8S_TOKEN_FILE\> mounted read-only.
