#!/bin/bash
source ./constants.sh

echo "Setting up bosh target"
/usr/local/bin/bosh target ${director_ip}

echo "Uploading stemcell"
/usr/local/bin/bosh upload stemcell https://storage.googleapis.com/bosh-cpi-artifacts/bosh-stemcell-3262.2-google-kvm-ubuntu-trusty-go_agent.tgz

echo "Uploading release"
/usr/local/bin/bosh upload release https://bosh.io/d/github.com/cloudfoundry/cf-mysql-release?v=23
/usr/local/bin/bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release?v=0.333.0
/usr/local/bin/bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/etcd-release?v=36
/usr/local/bin/bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/diego-release?v=0.1454.0
/usr/local/bin/bosh upload release https://bosh.io/d/github.com/cloudfoundry/cf-release?v=231

echo "Creating cloudfoundry.yml"
zone=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)
zone=${zone##*/}
region=${zone%-*}

cat > cloudfoundry.yml<<EOF
---
<%
# CF settings
director_uuid = "{{DIRECTOR_UUID}}"
vip_ip = "{{VIP_IP}}"
root_domain = "{{ROOT_DOMAIN}}"
common_password = "c1oudc0w"
deployment_name = "cf"
# Google network settings
google_region = "{{REGION}}"
network = "cf"
public_subnetwork = "cf-public-#{google_region}"
private_subnetwork = "cf-private-#{google_region}"
%>
ssl_cert: &ssl_cert |
  -----BEGIN CERTIFICATE-----
  MIIBrTCCARYCCQC8Nv/VzAW5gzANBgkqhkiG9w0BAQsFADAbMQ0wCwYDVQQKDARC
  b3NoMQowCAYDVQQDDAEqMB4XDTE0MDcyNDA0MjkzNloXDTI0MDcyMTA0MjkzNlow
  GzENMAsGA1UECgwEQm9zaDEKMAgGA1UEAwwBKjCBnzANBgkqhkiG9w0BAQEFAAOB
  jQAwgYkCgYEAusGqZW2nSyqSI5RY8Hm8270XfYEuR3kPVYuwwAftEi7BSaR+4fpb
  a9kXaJwcPMIecQOsPTByoqyXfseUx1yZVBEnq/7ZjYj1ipfGa99XfQEjCzXaS3Je
  NkdwhJf3IZf7XQMhSZMs7NmvZ6aD91st83NCr316fdDoKvRRi66YlOcCAwEAATAN
  BgkqhkiG9w0BAQsFAAOBgQCc6HCnAY3PdykXNXLyrnRk31tuHCrwSKSGH+tf24v8
  DO9wUuuja+jGYou5lE+lzRs8KBYR97ENb0hNC0oYrU3XWinWJAdM2Dp3/lWQJF9T
  9yQKNnctjW6U7YbCqkbkZXesZglSjtTnyiVlD59shmDNZZCQnbG7CLkrnlQGuM4n
  zg==
  -----END CERTIFICATE-----
  -----BEGIN CERTIFICATE REQUEST-----
  MIIBWjCBxAIBADAbMQ0wCwYDVQQKDARCb3NoMQowCAYDVQQDDAEqMIGfMA0GCSqG
  SIb3DQEBAQUAA4GNADCBiQKBgQC6waplbadLKpIjlFjwebzbvRd9gS5HeQ9Vi7DA
  B+0SLsFJpH7h+ltr2RdonBw8wh5xA6w9MHKirJd+x5THXJlUESer/tmNiPWKl8Zr
  31d9ASMLNdpLcl42R3CEl/chl/tdAyFJkyzs2a9npoP3Wy3zc0KvfXp90Ogq9FGL
  rpiU5wIDAQABoAAwDQYJKoZIhvcNAQELBQADgYEAVpFm7oKKgQsuK1RUxoJ25XO2
  aS9GpengE57N0LH1dKxyHF7g+fPer6YAwpNE7bZNjyPRkng33OJ7N67nvYtFs6eN
  CFBf8okWpmFgJ6gC5zNxYQRm1RU7+RUpM2ceMT1g14SmA5ffS48rYaSx2raKphYA
  KI1neJFzwM3gQfrwI+s=
  -----END CERTIFICATE REQUEST-----
ssl_key: &ssl_key |
  -----BEGIN PRIVATE KEY-----
  MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBALrBqmVtp0sqkiOU
  WPB5vNu9F32BLkd5D1WLsMAH7RIuwUmkfuH6W2vZF2icHDzCHnEDrD0wcqKsl37H
  lMdcmVQRJ6v+2Y2I9YqXxmvfV30BIws12ktyXjZHcISX9yGX+10DIUmTLOzZr2em
  g/dbLfNzQq99en3Q6Cr0UYuumJTnAgMBAAECgYEAjQFwcEiMiXpJAMgfJuIjsB1j
  QQVqNdi3tTVVbIgPfS0ED2A91M08fX9Z50gHIfDHHzlQsJqF00FQ2Q5DzQqjUMS+
  EJvVQsen71B8LNkKB+8GlJjTN+QoW0UAWtvK6gRYB4VIe+5LrWlioQWHucYH8UzB
  veyzthWQBPfxDkYrvdECQQDsR0T/oo0kN3GHcwRe4p4oVMUncu9pci8IRZf7gSKN
  8db+LVTSm7jrhUOmSmCL//A2VnoNpPriFaP573dHH9kLAkEAylg56itY8Kn9AAAk
  1BlFprO0Odecz8Cf8ZNzzpAvnN/AqRSF04PTUCRavJonGirW6tU+qgybMMO3uVHf
  9/W1FQJAQn/Ihp4sVS4ZkMKpTz8+viEln/W0NhxB6nUT0mBE5mhTVxRRFDlpsTe/
  k3TJeX2eEN0D2wU86xamIPjpvCXVgwJBAJ+CQ01tFHTLnEz20BF/Rp/uQ+HhLZW8
  pJlcgstQcKg63vaq3gBqiBdCQWEyKCcBpGCE8Bw/Sct8TgXCHEutHy0CQQCv14lC
  nM7h6y+I9r3cqZRBDMfWpvAl25doctNWY0McmudIT9FHIBtvayRnBqa9Z554Bk6S
  f+4pffb9Gl/e6Fxh
  -----END PRIVATE KEY-----

name: <%= deployment_name %>
director_uuid: <%= director_uuid %>


releases:
  - name: cf-mysql
    version: "23"
  - name: cf
    version: "231"
  - name: diego
    version: "0.1454.0"
  - name: garden-linux
    version: "0.333.0"
  - name: etcd
    version: "36"

compilation:
  workers: 6
  network: private
  reuse_compilation_vms: true
  cloud_properties:
    machine_type: n1-standard-8
    root_disk_size_gb: 100
    root_disk_type: pd-ssd
    preemptible: true

update:
  canaries: 1
  canary_watch_time: 30000-300000
  update_watch_time: 30000-300000
  max_in_flight: 32
  serial: false

networks:
  - name: public
    type: manual
    subnets:
    - range: 10.200.0.0/16
      gateway: 10.200.0.1
      cloud_properties:
        network_name: <%= network%>
        subnetwork_name: <%= public_subnetwork%>
        ephemeral_external_ip: true
        tags:
          - cf-public
          - cf-internal
          - bosh-internal

  - name: private
    type: manual
    subnets:
    - range: 192.168.0.0/16
      gateway: 192.168.0.1
      cloud_properties:
        network_name: <%= network%>
        subnetwork_name: <%= private_subnetwork%>
        ephemeral_external_ip: true
        tags:
          - cf-internal
          - bosh-internal

  - name: vip
    type: vip

resource_pools:
  - name: common
    network: private
    stemcell:
      name: bosh-google-kvm-ubuntu-trusty-go_agent
      version: latest
    cloud_properties:
      machine_type: n1-standard-4
      root_disk_size_gb: 20
      root_disk_type: pd-standard

  - name: common-public
    network: public
    stemcell:
      name: bosh-google-kvm-ubuntu-trusty-go_agent
      version: latest
    cloud_properties:
      machine_type: n1-standard-4
      root_disk_size_gb: 20
      root_disk_type: pd-standard
      target_pool: cf-public

  - name: cells
    network: private
    stemcell:
      name: bosh-google-kvm-ubuntu-trusty-go_agent
      version: latest
    cloud_properties:
      machine_type: n1-highmem-8
      root_disk_size_gb: 100
      root_disk_type: pd-standard

disk_pools:
  - name: consul
    disk_size: 1024

  - name: etcd
    disk_size: 1024

  - name: blobstore
    disk_size: 102400

  - name: mysql
    disk_size: 102400

  - name: diego-database
    disk_size: 1024

  - name: diego-brain
    disk_size: 1024

jobs:
  - name: nats
    templates:
      - name: nats
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: consul
    templates:
      - name: consul_agent
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    persistent_disk_pool: consul
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      consul:
        agent:
          mode: server

  - name: etcd
    templates:
      - name: etcd
        release: cf
      - name: etcd_metrics_server
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    persistent_disk_pool: etcd
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      etcd:
        peer_require_ssl: false
        require_ssl: false

  - name: diego-database
    templates:
      - name: etcd
        release: etcd
      - name: bbs
        release: diego
      - name: consul_agent
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    persistent_disk_pool: diego-database
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      etcd:
        machines:
          - etcd.service.cf.internal
        cluster:
          - name: diego_database
            instances: 1
        ca_cert: &etcd_ca_cert |
          -----BEGIN CERTIFICATE-----
          MIIC+zCCAeOgAwIBAgIBADANBgkqhkiG9w0BAQUFADAfMQswCQYDVQQGEwJVUzEQ
          MA4GA1UECgwHUGl2b3RhbDAeFw0xNTExMTgyMDI3MTZaFw0xOTExMTkxOTQ3MTZa
          MB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMIIBIjANBgkqhkiG9w0B
          AQEFAAOCAQ8AMIIBCgKCAQEAwAI/I5GhhpWpJdSUM5rrOWpoKvL9ylINZOxs1kcm
          2g35sipVE/+Vg+8tb3A7sOKLTa/+/yWNaY3o1sv+eIxjsHtIt7Tj1gkFZWpHZ6RX
          jkzyrPCTqaMCrcOjarRRdsI5ExA4CX8qsFFQrYv5Xrv0o0XfctXwAVkc68NxyHov
          v0x0h2ULvp1iff5QyT183LDjOUiiK3gqSrj6BpQy6yp/e/X/aZatQEjvaLuWqmU3
          Zv6WLMA36vPVr4JoZxu9beD4QW+5PBsmGz9yrpaB7jOnFwhU0zvtv/vSZxdrpLmY
          b4ZwXHMR2oY045OdJWI6bwXuOSofPj95aItjKVn5Swuy3QIDAQABo0IwQDAdBgNV
          HQ4EFgQUXMQUYHcIWzZ6aUtbc4Yv/4xGfjswDwYDVR0TAQH/BAUwAwEB/zAOBgNV
          HQ8BAf8EBAMCAQYwDQYJKoZIhvcNAQEFBQADggEBAEhU5Gl+ywoJPRyEvXcrlGdS
          fbvzIQyLS6C6GnXpDTqOLIXtTqrUJkqVH6GXBQcBShtXzfvW5Rua4HDEKj6wPF4j
          5QziIE0UrdJdFMupA3cPE449gITGFG20/O3xXGmeWzIijbFgKOEYyQIkExR3lcqb
          czPN1MMNB6pI+HZVk0sn2QPD3p5kTnJRF0/wvq1rUbQ1ddW1BroCDywTecAgGK1X
          k2OIFEg0Js7aX9/M/jLnNjTdjc5RUE45b0chPQJ9lv2Ub4jqItqtrZhy77a0e5Pb
          ucAbKSizVP/2rml1JzLmL6V4jJtI6RWrUHuCIQDCFBvqN6cHqoQW8x++UuuPe44=
          -----END CERTIFICATE-----
        server_cert: &etcd_server_cert |
          -----BEGIN CERTIFICATE-----
          MIIDgjCCAmqgAwIBAgIUM0sWbTuPAXAjWADfVZyGdLbHkw0wDQYJKoZIhvcNAQEF
          BQAwHzELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bpdm90YWwwHhcNMTUxMTE4MjA0
          NTA4WhcNMTcxMTE3MjA0NTA4WjBCMQswCQYDVQQGEwJVUzEQMA4GA1UECgwHUGl2
          b3RhbDEhMB8GA1UEAwwYZXRjZC5zZXJ2aWNlLmNmLmludGVybmFsMIIBIjANBgkq
          hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoK5LvNzQSCSKYlCtLOD/Ju67Xd6kRhiQ
          a1Up0Lg62j5HnzLCyTIpItj6w5hiIGgNhBwQvMEid8SnPAb8IT9NARKbDyNXPmg+
          hhfLoW2XTrZwnAP+ccocGcNiFAC/OPEsZUQ1XzY/8K+uAlhfp3Y7hWMNgpaQZlIw
          wPRs8SNfM0MxEYPttfQhMpkSAnLoKp0n/1iSKzzZmxziXThEDx0Ach3xeaGGjXWl
          r32jHTDfi7mEl+NqkhWQZu12/KI+jCTjYmQyny51EAYsXInhZET2uMboQzpNtuXi
          INHo+0h/gKbHi3RFwlXw4FbcoQ7HeAz0s32NV658sJLDJd+w5r/r3QIDAQABo4GS
          MIGPMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQUC7pemq7IcM9rRqjuIUcK6mQg
          yBIwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMD8GA1UdEQQ4MDaCGGV0
          Y2Quc2VydmljZS5jZi5pbnRlcm5hbIIaKi5ldGNkLnNlcnZpY2UuY2YuaW50ZXJu
          YWwwDQYJKoZIhvcNAQEFBQADggEBAD/bFCLpiH5zX9dcw4/No/Nmpootisw3TJlM
          MbV5h5OYb+5rft68j6LM+8gl7YPKol/1yR6z0uqh/Sn3EfkjXPEtL98LDDANSJMO
          8WCmaqnxFnqkZXkel75owrcXdAHIYBU65+v8XVhLdEh2eVcTG2PLBqdMqEr6zBGi
          NXl0cHpcu/icjA9NWUIJmliCk+jM4/ZLexZwUVnYXvaz8SwSxvpxb0rU4Si4pZQS
          dY8iQch9cK1rjICFQibQMz7o0rYtZpQx7OxoqK1hbWgyjFIRgQ8xGH8zqs+T2jYO
          ehq9BZC6Uz/XDuhiNuWhZzhqfYG9iEI8FDYnYR1PZbDAB8aPOps=
          -----END CERTIFICATE-----
        server_key: &etcd_server_key |
          -----BEGIN RSA PRIVATE KEY-----
          MIIEogIBAAKCAQEAoK5LvNzQSCSKYlCtLOD/Ju67Xd6kRhiQa1Up0Lg62j5HnzLC
          yTIpItj6w5hiIGgNhBwQvMEid8SnPAb8IT9NARKbDyNXPmg+hhfLoW2XTrZwnAP+
          ccocGcNiFAC/OPEsZUQ1XzY/8K+uAlhfp3Y7hWMNgpaQZlIwwPRs8SNfM0MxEYPt
          tfQhMpkSAnLoKp0n/1iSKzzZmxziXThEDx0Ach3xeaGGjXWlr32jHTDfi7mEl+Nq
          khWQZu12/KI+jCTjYmQyny51EAYsXInhZET2uMboQzpNtuXiINHo+0h/gKbHi3RF
          wlXw4FbcoQ7HeAz0s32NV658sJLDJd+w5r/r3QIDAQABAoIBAGPUpr3Ku6V2/nuj
          AFVX3W9E+CiUQaBDdscY/IfvTrF17G3ezeLPRXufL/4CWUUlIPCpt0RvAolDJ1xG
          QrQtbhxygOBg5r2haudJNX0wZ8fB1ik42ge8uMTQ/cjLxgMM5LZuMHLdc9CIdiaC
          3btf3A89wZEXFtRb0Gqx8lXH0kg4RLhk6zTnQ2JoeboiYq5DDY2O/gxNkbNSXCVA
          pLxqFCxt7pU5QscPtbmGk9Y2stRMjyp2CGIev/643yi0Q/SQqbn2SKZv32jIWmwx
          jCkZeQPbozjS/5bi555UZpEcHAMK076zYF7+lyvSkxP3Mp5zKLiMFIuX/5vU7Cae
          yzR8ZQECgYEA0tAz09jQq90CLb+TlKY4gBTvlM4JGZ1K5ci5qv5l3g8pM8XUgmQN
          6/42o3jTgmNvGKPF+aGOiEA1OXTWa7DG4YP1Slh8AYevJw+HnlKz4NKBlLkHwEhN
          hAo5rHyHFHJuZJQpquiBSkBpce6nNeTjJPesi6Y+oJXKvLXc0k6M6r0CgYEAwx82
          tBawJnhvBIkclUOZe0+RHeK3598dC8J5R3Bc5cM/0NVJg6m8PquhLEArXKkksIo4
          J/7BIw0M1A9ZxUvtqq/4nfuTMUy20RBTU4MAcVgNLOIw49sYe9s+cApM/5NqGbLU
          dnIsu5Vd2bZAJQK5TUowqjp32XcPjD5TAa5rp6ECgYBrHPSoeCqWmGXp/sQqrEZa
          9chBkGpZRG1w0YtdEYOKz6M8thDi65mTRghXCSZWwtUI7PXDf83e9tjUR8RG1XxH
          y3ePfeQMFvfs3dwnmpfg7LSAb387uMECDPv+4wrzXa0vl4SQXTCMHKw3Am6dWJ39
          A4b9McvyZgmr1q/Lf7Pj9QKBgBMU1VutMFLCylCOPA5YywSlFlLu3f898XA593RG
          B7+sZWw9v2+xxKf4Ts2uBM+N9vmQuscmgaq01wFR8vx5XWeox85jUNSsZOBzEUME
          d6Gd88Pk5tURkwZhvWxlhXwk5WZX97ERn1BE3iWxTfqQlqB5VeL/zsKkgw+69JEg
          hoShAoGAcginf7QsysxQ9J6of4djDX2UskLD6gJ82tYDIRmoYU7i4nhiAV5h97VC
          gZwLkJshvJobLOvWYHQz22hlvBCR+2f0nTV65qsQGS24p3fEptTQGtjR7MdK6hAt
          zcG+1F1Srm4249/fsSWBuNhc/fUZc44vmsU0/WAhPAbqEdHvlqI=
          -----END RSA PRIVATE KEY-----
        client_cert: &etcd_client_cert |
          -----BEGIN CERTIFICATE-----
          MIIDNzCCAh+gAwIBAgIUSiZNDq8jWIzmpucRnoryqSz2PTswDQYJKoZIhvcNAQEF
          BQAwHzELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bpdm90YWwwHhcNMTUxMTE4MjA0
          NTA4WhcNMTcxMTE3MjA0NTA4WjA6MQswCQYDVQQGEwJVUzEQMA4GA1UECgwHUGl2
          b3RhbDEZMBcGA1UEAwwQZXRjZF9jbGllbnRfY2VydDCCASIwDQYJKoZIhvcNAQEB
          BQADggEPADCCAQoCggEBANV/dP1u7KViVLefJxAbOkl4dXGAFfJRfKqQpg4CyA3w
          UHOA99H4cAcwbXoEOaDfqI8ShE0ST0IgenkkvkT6w+p4f4NCMG/OoXxeDaZE6dCK
          gsq/AMI67tFpt2YXN6P19Izzs9BQpk9U/v8SZwoJXMVj0Dba9zD8ulG8LE7it4PF
          a+YW3rIDdzwQHMZtgh0tzcvjDFc0suvQSsqakh+Ng1XPgVVKKe4T79BQOOkXgFNL
          xbIqsnGWJtAwd3D41b0EevSjQTlgdoJKvY/X5wGG1x1l4qKEuZmqgiDH4zRLdTGG
          /IXLOIr0Zcs+CVBLME41uMFbcjzSMCd93+mqOpRxMxcCAwEAAaNQME4wDgYDVR0P
          AQH/BAQDAgeAMB0GA1UdDgQWBBRFAsRZSfanZpJK+ScqtNAHveXxPTAdBgNVHSUE
          FjAUBggrBgEFBQcDAgYIKwYBBQUHAwEwDQYJKoZIhvcNAQEFBQADggEBAFLr414b
          Pxb0VYCz+OmqaZT5gvZ7uG4wBlmTdMqNIBmU2hZJmtYA/bnLXtzRYlyHlBES/cEK
          K4mwl8xXWE8131qaF1ua6ZOmkWJGJYl8PIW/V3hL+9q/1GD7RP9LgrQEF9Mdb4PW
          i6XRdEB5Z2X97JMOP4XJ1n+trqZaAYEboFvh/ICP06C4p3B+pM7btTyJ1qv1T/Gh
          WMV2qiVP9yIfI8UbU2MaaXlF6bW5xWgmgt+6NIPyyXh5DQg21smBKcybAjGNVOyC
          ZxT9QWKgoJVvpyFlYq5rg05MZXtKzQtozVECAa3F+5pH2WZjjm12g3Em3pJjZ6k1
          sO4Xc1kAHbgvjQ4=
          -----END CERTIFICATE-----
        client_key: &etcd_client_key |
          -----BEGIN RSA PRIVATE KEY-----
          MIIEpQIBAAKCAQEA1X90/W7spWJUt58nEBs6SXh1cYAV8lF8qpCmDgLIDfBQc4D3
          0fhwBzBtegQ5oN+ojxKETRJPQiB6eSS+RPrD6nh/g0Iwb86hfF4NpkTp0IqCyr8A
          wjru0Wm3Zhc3o/X0jPOz0FCmT1T+/xJnCglcxWPQNtr3MPy6UbwsTuK3g8Vr5hbe
          sgN3PBAcxm2CHS3Ny+MMVzSy69BKypqSH42DVc+BVUop7hPv0FA46ReAU0vFsiqy
          cZYm0DB3cPjVvQR69KNBOWB2gkq9j9fnAYbXHWXiooS5maqCIMfjNEt1MYb8hcs4
          ivRlyz4JUEswTjW4wVtyPNIwJ33f6ao6lHEzFwIDAQABAoIBAQCp+bTZxQNxVI0g
          N/ywrQzFy7qtJ43Rg6DeZxVdmEdQGaDjpK0pJUOD5cFzYIPFGewoJFTiy44Alr0L
          T/6QCpoKRe83QG4xxe/5hSQW2UzR9ETXSCRBfwv9+83A4QEyb7JIugnR8zPFe2Ud
          DLiuW+/ZU3NFCSW+gaeRRWB9WbFDnWhL3u0xpdPYyVDoItKqH+6KHMkZ8vpfmsbh
          8QZOPb7jcGU3kAEbIG9cg+hl/vZI8el3Mni5tZQoCK875+mmezsU54nAHyBOmuDR
          u/axX8lTnI6AMJTpC9yxtDcEKf+Jpf0GQz6G90mT8oMhyQAiCLxWWJq/rD5aM0uU
          xt3DS6exAoGBAPcIaN0mKTgKAjYUcKhDrbxb1c9Qk8pM4UtQSCujINTLJi9unJZv
          am6S9SNYfNBMsPmgczNNAQlscZtstk6ZAUNAdMzrUxZuWIopbznjSoD1SjVEoo1X
          yvbu+YGN9TNzSjofLDczbAucFuaQ+jKPHzfhdECd49nRhGgcEFd/avO/AoGBAN0/
          ayWDGrbW41wGLXMZvIz4YPHs3+UosvEHqQpzb5DtBKTc+2DQ8HznFe3ltB2wTPDV
          B7Yc8RckC/3Dw8xh5vWBn4S/cbGiDbBqmZm8e81PnCPrtjJQSMvtL6CP9rsq+Emf
          0Dyia2gqjN049uQSOiL4mOC2m/WFYvOEXclDlDapAoGAexqKv2Ir+kwqi+6lsYSA
          iLQvGW/rJk4nm5N3U5+oVcKi1dJGYEVHgbDkTmfjUx5UtyE5J2CBWsPa3XxQYVyo
          H254hkHjFvOIVdmOHwfgceFKyL7aTptofqPaXLB0d95FKC+uphePCT4Qv3eR5y4h
          fYRxnV3RVROu6v7JOgE6OBsCgYEAhfQCrEiPYQoDx9CZrel0JimvkGnpOPaGOLZ5
          mzE+6BEI0cRVkk2OfSDwPwPnJF58hweDzrgBJBCYDgF7x3+y9QuRCC9c576E6T3x
          V4otrqW3lGv++MFxAb7OKjlfmfyvLOxMiJmRzBSPCtWVbYq3ljrLXKpTDLjAq02F
          9vgqgVkCgYEAiBclzilLmCLVyI8P2avm+QFPsGh2A/012fE1Utubf+3pGE6nBi/2
          dC9GhjOReVMVqH7PIgaeNQtGVVG4VxRBW8aiHaV63xYTN7Cxeks4GSIGNBKZANuJ
          u/wqjmT4rRYCre4rXUNBRWVvADBotzCoJGfl4p3ZttgcvDGKncdHfQo=
          -----END RSA PRIVATE KEY-----
        peer_ca_cert: &etcd_peer_ca_cert |
          -----BEGIN CERTIFICATE-----
          MIIC+zCCAeOgAwIBAgIBADANBgkqhkiG9w0BAQUFADAfMQswCQYDVQQGEwJVUzEQ
          MA4GA1UECgwHUGl2b3RhbDAeFw0xNTExMTgyMDI3MTZaFw0xOTExMTkxOTQ3MTZa
          MB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMIIBIjANBgkqhkiG9w0B
          AQEFAAOCAQ8AMIIBCgKCAQEAwAI/I5GhhpWpJdSUM5rrOWpoKvL9ylINZOxs1kcm
          2g35sipVE/+Vg+8tb3A7sOKLTa/+/yWNaY3o1sv+eIxjsHtIt7Tj1gkFZWpHZ6RX
          jkzyrPCTqaMCrcOjarRRdsI5ExA4CX8qsFFQrYv5Xrv0o0XfctXwAVkc68NxyHov
          v0x0h2ULvp1iff5QyT183LDjOUiiK3gqSrj6BpQy6yp/e/X/aZatQEjvaLuWqmU3
          Zv6WLMA36vPVr4JoZxu9beD4QW+5PBsmGz9yrpaB7jOnFwhU0zvtv/vSZxdrpLmY
          b4ZwXHMR2oY045OdJWI6bwXuOSofPj95aItjKVn5Swuy3QIDAQABo0IwQDAdBgNV
          HQ4EFgQUXMQUYHcIWzZ6aUtbc4Yv/4xGfjswDwYDVR0TAQH/BAUwAwEB/zAOBgNV
          HQ8BAf8EBAMCAQYwDQYJKoZIhvcNAQEFBQADggEBAEhU5Gl+ywoJPRyEvXcrlGdS
          fbvzIQyLS6C6GnXpDTqOLIXtTqrUJkqVH6GXBQcBShtXzfvW5Rua4HDEKj6wPF4j
          5QziIE0UrdJdFMupA3cPE449gITGFG20/O3xXGmeWzIijbFgKOEYyQIkExR3lcqb
          czPN1MMNB6pI+HZVk0sn2QPD3p5kTnJRF0/wvq1rUbQ1ddW1BroCDywTecAgGK1X
          k2OIFEg0Js7aX9/M/jLnNjTdjc5RUE45b0chPQJ9lv2Ub4jqItqtrZhy77a0e5Pb
          ucAbKSizVP/2rml1JzLmL6V4jJtI6RWrUHuCIQDCFBvqN6cHqoQW8x++UuuPe44=
          -----END CERTIFICATE-----
        peer_cert: &etcd_peer_cert |
          -----BEGIN CERTIFICATE-----
          MIIDgjCCAmqgAwIBAgIUQWAM/+Fzbw9eWshdyUorgAD5mOMwDQYJKoZIhvcNAQEF
          BQAwHzELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bpdm90YWwwHhcNMTUxMTE4MjA0
          NTA4WhcNMTcxMTE3MjA0NTA4WjBCMQswCQYDVQQGEwJVUzEQMA4GA1UECgwHUGl2
          b3RhbDEhMB8GA1UEAwwYZXRjZC5zZXJ2aWNlLmNmLmludGVybmFsMIIBIjANBgkq
          hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0JMW2C6W9q+fa/2tHMFUN1ToAZ9RwBRP
          JCXARXFj52pF8jjqzudT6fb81Yw0ak45hAbDuOreaHShtLLFqzkIhnmh2WJllB2l
          f7x1Mbs4S8tfkNgCVb526LLpAYFfLJ6K4KS8Dk8L/8d291Wr0/kVlB9ZuFcXE4Ug
          j1U+Ali08PfKduVFPOukkzJ2kS70s0krVSTrcXBRGmUvthBLf+LkXTPpmxGDnQcx
          Z4A5CMtE2uEbRrlQPmC6CWWGsjggmJ23lUcwLQrH/TiEfxrNV0A5oIg0AOP5ps4F
          PpUrFrjsPHneJds/3inmU9UIu1eLbkTGHGw+LXG/JP0Lng15frpruwIDAQABo4GS
          MIGPMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQUP2awOWj18GEPeR4lmqzB3IbZ
          J5cwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMD8GA1UdEQQ4MDaCGGV0
          Y2Quc2VydmljZS5jZi5pbnRlcm5hbIIaKi5ldGNkLnNlcnZpY2UuY2YuaW50ZXJu
          YWwwDQYJKoZIhvcNAQEFBQADggEBAAHZ32ebyGU1GjO8pPRIcHi2RbltX345rJ2o
          QYBpbKf+k/wcUBgMqI+M0qqjN+LLm86hvjba7uGAls3rB1tQLPGIawKVNy+HtxU7
          2n7ah4Sv/5dragOsv1MtyfHp63NqfB7GFL+CJfuHoVDFF/6s3PiJEtLX6vJVvXZZ
          0kbDmOsDQHPPdVCu6wXfArXlIbo5gP3kerzkaHNftn46I8djCebPuaJu0aQ+0Sj7
          rYhaet+HlU7w77LUWlrZsCQF5ftApOFcZkEwvYLcJo1gqER1GO75ViG8+QVfS0zC
          hQVgyqFWYlnsWCrZM4qZqVR9zbuaQ8K+qIhVuWX33L6A2XinlC4=
          -----END CERTIFICATE-----
        peer_key: &etcd_peer_key |
          -----BEGIN RSA PRIVATE KEY-----
          MIIEpAIBAAKCAQEA0JMW2C6W9q+fa/2tHMFUN1ToAZ9RwBRPJCXARXFj52pF8jjq
          zudT6fb81Yw0ak45hAbDuOreaHShtLLFqzkIhnmh2WJllB2lf7x1Mbs4S8tfkNgC
          Vb526LLpAYFfLJ6K4KS8Dk8L/8d291Wr0/kVlB9ZuFcXE4Ugj1U+Ali08PfKduVF
          POukkzJ2kS70s0krVSTrcXBRGmUvthBLf+LkXTPpmxGDnQcxZ4A5CMtE2uEbRrlQ
          PmC6CWWGsjggmJ23lUcwLQrH/TiEfxrNV0A5oIg0AOP5ps4FPpUrFrjsPHneJds/
          3inmU9UIu1eLbkTGHGw+LXG/JP0Lng15frpruwIDAQABAoIBAG62FMMtf75znFiz
          L4d661vverMZwUgGv7d9PmDd/lyg4X3gTmsDCVzAWJZ1tIDVAtycxplKOkIR3p/O
          4POw82CGAa4k96w2TFnQTBjYutoompKExkCDOBTumpXM+RrzEN6LMrMZrFHZq8E/
          vVRn+9dDCNm7iKk42f6bDa4rLehVeO7zhGpQzozBoqMlCGZ5I1IDakPGmzpk5B2H
          y2fml0tMVEd7hUEFKNE2t0y8fVW8CiPmR2htEBijSSw+Z3EQeozZEzmJNCEx8Mtb
          bUfCgbvmO0tmAjgWIbUBB+vf6sr2vJapBdbkd6/Q30b2IB0Q9faSkOjCA9ycu7N/
          3CPjbiECgYEA+9vfTykwlhvYY8uGvPigBmvnby7nCQWC186D0Gjt3SkYxY7Z0+pW
          v8YnYFiPDZ7FMHf808osgNXaWvxQdWWN2sAd5TrwYPa68Gzw/v/Lq2WzR1kdkLGL
          WlEbHiuy5ZTsNNy2/i17FqgdoZglv52DqPzWOZMzXVelpLy91UQ8APECgYEA1AEG
          KECgcnUGZ7gvYLNi0KfuLLT6Zdd255Cu1Vu4ZxXvxQG3tOd8znRwJho+guJoFaNH
          ItofqIn3O5SG/rTtlj/ZN9oO0lygwT0d18RobJiK2p0YRItvNNBFQc0Q4hDqqUDb
          sUbBDrTcEKmJ66RbRXggX1C96QF2GgNOTgiWd2sCgYEA+oGSVmlQsy1VCMWp6ZGd
          kWWIF1VeZOG/Z6k4AHYtiNlUk0Nns9kUmcCc776F4vU1iuT9ayZfJ3INsovd9zag
          ZqDJ23PJHZirDXI+LlP8nykTrXac6os9YQLk5xht4t5CJr4VoTFZiYqDlnP/r9wa
          1V1OMowP/dqsnfNBGbu5tvECgYA4VQVT0MhRYXMQQEqmgUPyeYy56GTYhsYbhcBP
          BQ4cpiGN0YUE1rW9Dgd2uGZ/1LUfesE+K4NZ/z7oX/D24RB4agLH6nMhxmcYsaqq
          WI/+uxG6QR/fpsUn3WdpspmX2DLiQk+d7VUDGV+YNdRl/sgZz2+apBOyRCcjhlla
          NsH0fQKBgQCG8cENarNWXQW/oaYvSKzK226ckbtYdAS7im5rzYqxcuDKvI2ocMtp
          EjNJTCQK8xvxW0nnefLYLbUD+ZA8L9DrEf+Sgr3Zwp+m58nL9XlGHeZE2wymwqCB
          ETMxxm/r9PEu5JFFIl3c56/L9REZYDyhpwR5tELQCFxGuKT5Wxlfnw==
          -----END RSA PRIVATE KEY-----
      consul:
        agent:
          services:
            etcd: {}

  - name: blobstore
    templates:
      - name: blobstore
        release: cf
      - name: route_registrar
        release: cf
      - name: consul_agent
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    persistent_disk_pool: blobstore
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      route_registrar:
        routes:
          - name: blobstore
            port: 80
            registration_interval: 20s
            tags:
              component: blobstore
            uris:
              - "blobstore.<%= root_domain %>"
      consul:
        agent:
          services:
            blobstore: {}

  - name: router
    templates:
      - name: gorouter
        release: cf
      - name: ssh_proxy
        release: diego
      - name: consul_agent
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common-public
    networks:
      - name: public
        default: [dns, gateway]

  - name: mysql-proxy
    templates:
      - name: proxy
        release: cf-mysql
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: mysql
    templates:
      - name: mysql
        release: cf-mysql
    instances: 1
    resource_pool: common
    persistent_disk_pool: mysql
    networks:
      - name: private
        default: [dns, gateway]

  - name: cloud-controller
    templates:
      - name: cloud_controller_ng
        release: cf
      - name: metron_agent
        release: cf
      - name: consul_agent
        release: cf
      - name: route_registrar
        release: cf
      - name: go-buildpack
        release: cf
      - name: binary-buildpack
        release: cf
      - name: nodejs-buildpack
        release: cf
      - name: ruby-buildpack
        release: cf
      - name: php-buildpack
        release: cf
      - name: python-buildpack
        release: cf
      - name: staticfile-buildpack
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      route_registrar:
        routes:
          - name: api
            port: 9022
            registration_interval: 20s
            tags:
              component: CloudController
            uris:
              - "api.<%= root_domain %>"
      consul:
        agent:
          services:
            cloud_controller_ng: {}

  - name: clock-global
    templates:
      - name: cloud_controller_clock
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: cloud-controller-worker
    templates:
      - name: cloud_controller_worker
        release: cf
      - name: metron_agent
        release: cf
      - name: consul_agent
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: collector
    templates:
      - name: collector
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: uaa
    templates:
      - name: uaa
        release: cf
      - name: metron_agent
        release: cf
      - name: consul_agent
        release: cf
      - name: route_registrar
        release: cf
      - name: statsd-injector
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      route_registrar:
        routes:
          - name: uaa
            port: 8080
            registration_interval: 20s
            uris:
              - "uaa.<%= root_domain %>"
              - "*.uaa.<%= root_domain %>"
              - "login.<%= root_domain %>"
              - "*.login.<%= root_domain %>"
      consul:
        agent:
          services:
            uaa: {}

  - name: diego-brain
    templates:
      - name: auctioneer
        release: diego
      - name: cc_uploader
        release: diego
      - name: converger
        release: diego
      - name: file_server
        release: diego
      - name: nsync
        release: diego
      - name: route_emitter
        release: diego
      - name: stager
        release: diego
      - name: tps
        release: diego
      - name: consul_agent
        release: cf
      - name: metron_agent
        release: cf
    instances: 1
    resource_pool: common
    persistent_disk_pool: diego-brain
    networks:
      - name: private
        default: [dns, gateway]

  - name: diego-cell
    templates:
      - name: rep
        release: diego
      - name: consul_agent
        release: cf
      - name: garden
        release: garden-linux
      - name: rootfses
        release: diego
      - name: metron_agent
        release: cf
    instances: 3
    resource_pool: cells
    networks:
      - name: private
        default: [dns, gateway]

  - name: doppler
    templates:
      - name: doppler
        release: cf
      - name: metron_agent
        release: cf
      - name: syslog_drain_binder
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: loggregator-trafficcontroller
    templates:
      - name: loggregator_trafficcontroller
        release: cf
      - name: metron_agent
        release: cf
      - name: route_registrar
        release: cf
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      route_registrar:
        routes:
          - name: doppler
            port: 8081
            registration_interval: 20s
            uris:
              - "doppler.<%= root_domain %>"
          - name: loggregator
            port: 8080
            registration_interval: 20s
            uris:
              - "loggregator.<%= root_domain %>"

  - name: smoke-tests
    templates:
      - name: smoke-tests
        release: cf
    lifecycle: errand
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: diego-acceptance-tests
    templates:
      - name: acceptance-tests
        release: diego
    lifecycle: errand
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: acceptance-tests
    templates:
      - name: acceptance-tests
        release: cf
    lifecycle: errand
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]

  - name: acceptance-tests-internetless
    templates:
      - name: acceptance-tests
        release: cf
    lifecycle: errand
    instances: 1
    resource_pool: common
    networks:
      - name: private
        default: [dns, gateway]
    properties:
      acceptance_tests:
        include_internet_dependent: false

properties:
  network_name: private
  networks:
    apps: private
    services: private

  ssl:
    skip_cert_verify: true
    https_only_mode: true

  syslog_daemon_config: {}

  metron_agent:
    zone: default
    deployment: <%= deployment_name %>

  metron_endpoint:
    shared_secret: "<%= common_password %>"

  nats:
    user: nats
    password: "<%= common_password %>"
    port: 4222
    address: 0.nats.private.<%= deployment_name %>.microbosh
    machines:
      - 0.nats.private.<%= deployment_name %>.microbosh

  consul:
    encrypt_keys:
      - "<%= common_password %>"
    agent:
      servers:
        lan:
          - 0.consul.private.<%= deployment_name %>.microbosh
    ca_cert: &consul_ca_cert |
      -----BEGIN CERTIFICATE-----
      MIIC+zCCAeOgAwIBAgIBADANBgkqhkiG9w0BAQUFADAfMQswCQYDVQQGEwJVUzEQ
      MA4GA1UECgwHUGl2b3RhbDAeFw0xNTExMTgyMDI3MTZaFw0xOTExMTkxOTQ3MTZa
      MB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMIIBIjANBgkqhkiG9w0B
      AQEFAAOCAQ8AMIIBCgKCAQEAwAI/I5GhhpWpJdSUM5rrOWpoKvL9ylINZOxs1kcm
      2g35sipVE/+Vg+8tb3A7sOKLTa/+/yWNaY3o1sv+eIxjsHtIt7Tj1gkFZWpHZ6RX
      jkzyrPCTqaMCrcOjarRRdsI5ExA4CX8qsFFQrYv5Xrv0o0XfctXwAVkc68NxyHov
      v0x0h2ULvp1iff5QyT183LDjOUiiK3gqSrj6BpQy6yp/e/X/aZatQEjvaLuWqmU3
      Zv6WLMA36vPVr4JoZxu9beD4QW+5PBsmGz9yrpaB7jOnFwhU0zvtv/vSZxdrpLmY
      b4ZwXHMR2oY045OdJWI6bwXuOSofPj95aItjKVn5Swuy3QIDAQABo0IwQDAdBgNV
      HQ4EFgQUXMQUYHcIWzZ6aUtbc4Yv/4xGfjswDwYDVR0TAQH/BAUwAwEB/zAOBgNV
      HQ8BAf8EBAMCAQYwDQYJKoZIhvcNAQEFBQADggEBAEhU5Gl+ywoJPRyEvXcrlGdS
      fbvzIQyLS6C6GnXpDTqOLIXtTqrUJkqVH6GXBQcBShtXzfvW5Rua4HDEKj6wPF4j
      5QziIE0UrdJdFMupA3cPE449gITGFG20/O3xXGmeWzIijbFgKOEYyQIkExR3lcqb
      czPN1MMNB6pI+HZVk0sn2QPD3p5kTnJRF0/wvq1rUbQ1ddW1BroCDywTecAgGK1X
      k2OIFEg0Js7aX9/M/jLnNjTdjc5RUE45b0chPQJ9lv2Ub4jqItqtrZhy77a0e5Pb
      ucAbKSizVP/2rml1JzLmL6V4jJtI6RWrUHuCIQDCFBvqN6cHqoQW8x++UuuPe44=
      -----END CERTIFICATE-----
    agent_cert: &consul_agent_cert |
      -----BEGIN CERTIFICATE-----
      MIIDODCCAiCgAwIBAgIUPw2F4qNDFmNRB3e1QfQ2R0yOLf4wDQYJKoZIhvcNAQEF
      BQAwHzELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bpdm90YWwwHhcNMTUxMTE4MjA0
      NTA3WhcNMTcxMTE3MjA0NTA3WjA7MQswCQYDVQQGEwJVUzEQMA4GA1UECgwHUGl2
      b3RhbDEaMBgGA1UEAwwRY29uc3VsX2FnZW50X2NlcnQwggEiMA0GCSqGSIb3DQEB
      AQUAA4IBDwAwggEKAoIBAQDHMhvi2/nxTQuLjX8AQFnzxVa/o0L3RoXUNE48gkQv
      XeJjAdxt1FLLRXGE7lWz0M8nRTjaFo4VGAvG8NegrpKT2FKbM/2TAVsriE/4n1gp
      IjNfo5O2D4+Woj4CnfeWgUh+OkuJEpQenxRBmGOnrapuplh1rNCjheVuOtOb+OeY
      duLmlr3q6if4eV1XU1Q1GUPB9i6WuxC9GZr2Ech3Nm07vNSfSPcw+glo2uLIB+hG
      F784uwz9CJ4bMHx0rkhiVDOFP8gmfG+3PTp0oBmCoGqxPZDE/pnnnjpU9hbJmfbs
      6fpn6qMZJkBqTDiAlE8PQyQffF7/sejnQ4M9sY9xcYDnAgMBAAGjUDBOMA4GA1Ud
      DwEB/wQEAwIHgDAdBgNVHQ4EFgQUlkO9Jqt/pPw5zaMM3fpaT/4/G6YwHQYDVR0l
      BBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMA0GCSqGSIb3DQEBBQUAA4IBAQCmqnZf
      R4daySfzszrSTncpMS3d0d4sG0r0Tre0sYq/lj8IFRfgVbn2dMvkqv9RrroWk+QQ
      Ge1vuS3NPJN1sBLK5VBEnMrApiZMLoQD4v0Lw/yWn0+WPbzTuS7aAc2SEhgIMqIQ
      y9dsVffYC+B3Q7yMVSSOEagJghpw2+T9Xn5DxaOOtgu8EDdEcqWCtLjgnQFPXbxq
      p4IBPKNPYQGHmGUc5/6pt4DAcJj2IO9kumCs5ELYhEpDqSWEwtDfCGiP/xbOnEvQ
      ydBqXP21/SxVZnrB+4WDTeI27KUrhJ72An3VK+AaMmm+AHP0IqxxvDjlKARlCR41
      Emkgj/LIoTLSGqew
      -----END CERTIFICATE-----
    agent_key: &consul_agent_key |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEAxzIb4tv58U0Li41/AEBZ88VWv6NC90aF1DROPIJEL13iYwHc
      bdRSy0VxhO5Vs9DPJ0U42haOFRgLxvDXoK6Sk9hSmzP9kwFbK4hP+J9YKSIzX6OT
      tg+PlqI+Ap33loFIfjpLiRKUHp8UQZhjp62qbqZYdazQo4XlbjrTm/jnmHbi5pa9
      6uon+HldV1NUNRlDwfYulrsQvRma9hHIdzZtO7zUn0j3MPoJaNriyAfoRhe/OLsM
      /QieGzB8dK5IYlQzhT/IJnxvtz06dKAZgqBqsT2QxP6Z5546VPYWyZn27On6Z+qj
      GSZAakw4gJRPD0MkH3xe/7Ho50ODPbGPcXGA5wIDAQABAoIBAQCpjhywkUCCxmsi
      YdIN+7jVyE9cFnNFGpGGHPPPi67QhuDSF95y2n2TK0xCs8Ddq8r5CXIoKXTNvccg
      kxdoXdDE6ij+lVWuEURynLg90Bzx/nuuWAW+viYiOX4BKkd6pBd54tMzHU5Zdl1+
      rGF/dFMTlqLLn8uEtc+icY54QHmai297YVuo3nXi+ALoUtm0pnahKuDZ2L6pRKKh
      U2xs1W1m32JFW1otFzwdksDw0NwIFNlgJGAg9e/ZbWJun8dMUHkyHBfodm9Edg30
      iPyixcxQELzwvkN4tdZRpX+7t96O0q7rUxgdn2bSdcR6HH+vhZQcsjjFzrczwcRC
      zs405j/5AoGBAOZFbdl0u4HLuGXxCyO7HiglQt4XBNeF3FY6oSXkLQjrXoqzLYDo
      N89K5itlyNDhnlCLnRCwQ+ylF3E3XH7KVS8fhL/1Pxl+lClutHH6Y5JI7w6BamI2
      PrXTSj9COrEU7pFLaW/jVLCxVOV9OSjvBUjexD1ilXOPgKsmG0vMf8n9AoGBAN1z
      z77TaapW9txZo+kXcINEQN9piOiuukLF2QJt4BD/l8eZYK5IRmQAi5oTVFuTqgAu
      Yxvvaun5SKpDhLCF+dyAiwahJ9x+JEaiXt7v1Vt6/jgGVlL3N40sSvl8m6sCuS2V
      CmDfX1HTepp6mRQ83L/So+e8jGmoLNUpZGUeQOmzAoGAYB5DCC4txrQeuI6xM6z7
      nY5QJxw8rSn3GxdGBOcF1V9KC2NXbyN/iEufYCYQeQB0cPKWEU1CTRlse5m8RkB2
      5kClzOq1+BJaDiFjuN/niDxhbRCgM3apHoSfzV/718cA/i0YSdf+lfKvmUt3/Joo
      /o3eJDFuaNpRvx8c7bri7JECgYBCUS5DbThVhJmEv2twoE5XYRc0UHxpgfnRiUJF
      kfXp4UDoyyvCxW4fAHLN/z/h9MSSLVIMyZPw4XA7XODdpCGBQRVhNN2lEDl41aMn
      jBcOwDRlPrCXQ+Vk54DEWeacPcKKvflPrVT0QiqTHGe/QcKxxzjCaxp5gZ17cFva
      VEcINQKBgQDTSoqXB8+h+zRUho7pRhIEWWLM0bi+xVdW+KuCobW5kqvgdzxsK5Ba
      GAvb1l59I2gfaGAIWmhMkkh6Ec1MTb9EZySXflCRD1nrqUsSbuna5Qkyg0zSdwAw
      H30+qi9NvXubdjG6/6x9nUDB1pOK0aMVN9ADQDYVWZI7CpijlXMwHg==
      -----END RSA PRIVATE KEY-----
    server_cert: &consul_server_cert |
      -----BEGIN CERTIFICATE-----
      MIIDYTCCAkmgAwIBAgIVANZWS6JLY+HCP3c1AL52RxetpllbMA0GCSqGSIb3DQEB
      BQUAMB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMB4XDTE1MTExODIw
      NDUwN1oXDTE3MTExNzIwNDUwN1owQDELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bp
      dm90YWwxHzAdBgNVBAMMFnNlcnZlci5kYzEuY2YuaW50ZXJuYWwwggEiMA0GCSqG
      SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDLEmOSImQmDQ/zJI7VF1AcOXz3ypEwG19m
      idv38yCXU4rt1Hp2l1utef7yT0f0PvE3q6AORv3xS6LqStnGgyNSFvL7GZz6Onji
      Yc3H5Bn7CyshvMQHZYAdyeddHf9ydyPUUlDaurzvgYPeFi7WrnvOplNenG5XoPWc
      vmm0SU/CzrpFkiAHDXpFZ0OWWFB+ogeemngWLefLkFMPkCmHt2dbJEdSj1jdfRhn
      JDZILdROyCSKVSEzQJHsrtnNh4h/Zxm7BA1iANSk9XVSH+3MfhnoaKIMYGhqmPIX
      Aa6Uti5wvwpl11343ZAZrwMnovdUICazxubEdBxtXxPUuW7JMhgxAgMBAAGjczBx
      MA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQUPXokXsQs7Qv/tv9g46zOYabebrEw
      HQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMCEGA1UdEQQaMBiCFnNlcnZl
      ci5kYzEuY2YuaW50ZXJuYWwwDQYJKoZIhvcNAQEFBQADggEBACkF/0KVj/rMdMFw
      jXbY0kxIRUqln4P+De4dSpnDmxFpnm6vDCJpT6d1K7KjL2GgtDW50M8qEGA1Zbso
      9mCOXV5VuUWsyVISGoCGkUvNQzYRl/PGgRtD90bL/dKjl+JIUKFHDmZIplaYJXzo
      DWqJKPSDKqPFa2T+pqwrYrBQAaC9eITCE9d9qFE9NY49wDHnscXwSQm2XOQ+co81
      Sm+tt4lLCgnprZ90q9mixYCRaVsZjqazHpEP6e4hqSzqAoRmT0ex4hkdjZTufCZH
      DC23NLSnpdIJuSYfNA16xNJY2nOqL2t33ow3yIVIzjbjnCEY4NtkTynQxUuUf4O4
      lG3loH0=
      -----END CERTIFICATE-----
    server_key: &consul_server_key |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpgIBAAKCAQEAyxJjkiJkJg0P8ySO1RdQHDl898qRMBtfZonb9/Mgl1OK7dR6
      dpdbrXn+8k9H9D7xN6ugDkb98Uui6krZxoMjUhby+xmc+jp44mHNx+QZ+wsrIbzE
      B2WAHcnnXR3/cncj1FJQ2rq874GD3hYu1q57zqZTXpxuV6D1nL5ptElPws66RZIg
      Bw16RWdDllhQfqIHnpp4Fi3ny5BTD5Aph7dnWyRHUo9Y3X0YZyQ2SC3UTsgkilUh
      M0CR7K7ZzYeIf2cZuwQNYgDUpPV1Uh/tzH4Z6GiiDGBoapjyFwGulLYucL8KZddd
      +N2QGa8DJ6L3VCAms8bmxHQcbV8T1LluyTIYMQIDAQABAoIBAQCoio2bhvGp5yN6
      wLfPQjcaBdijbDuOOtm2J+sqYl6FWjAvbi9p5/uOAnfHsmdc3zSi6M3Bq8guEYGY
      hSE0MjkJc8SdBUgVIpyb/2KkabvqcP2OVbY5EVQA5UciMLiHzzwsh1lWALC487x3
      gd/EDDLzc3Y0Sw8FqbDQM/VVTZdmbWKykZeiIJ1MI4pb2pW0nUtwC8kes2e08EtU
      Tw4zq1Y779abeiSqxXTtU22EEHdH4xDv2/jLVrIrhNBMhznujPXl3IN4wsd0ec08
      xma00IfcY0aoITTqfRSQFpDRn+XPyNSvJksAp4h0/8p/CQ9RXyDlMIyYW5P1UdKt
      s3uOtX9FAoGBAP74iJEAjHlD7P+judlq0Vr54upsGokZozYZiJ3JjUmWNZXN8ryh
      LF9pLvzpQZiIUeQyqwQm6VcMbQ4aA7aLB0IbL3MsXf4uX+QpA0OxsKc2FpxM7pB5
      pp6KP5JU2Jtim7SblfgFAkyqQNKQM4nfPA4OoW8X7WDMSkO42nwLVCDPAoGBAMvk
      Oilhddj5OlbtWRbA5DrHGzP8EdMCcd9a4NeOZVVyG3a0SibmB9uy3T2XFxDMc58J
      jln9te55fa1dxjxlxxiHE7445rWAotc2xZs2XNP4e+ySJ6GjoOAqL1ku+Hca2hhi
      dWxNRvm/fJNBJNZlJ7VbBF9Z6s40ym59OBjn2nb/AoGBAJta2/teFjmdRb7OB+ON
      zlpcgALOM6ztziCclj1uHYSE3cmVXx3IJr1L3bGEfs9t4Ffm94TkILFFhP1epHyJ
      YbbJ0bOfiPXjU9I1myOYFUcNEeHSjlnBheB75BhJUmH7R1xYoJwqkSgdZLnn2z9a
      ocD+8SY7sguU7nstGxMR5ATJAoGBAML80Y6PcRd+SYemVuPGtr1rep19fEJS/TnA
      fHRI7qoHhTJBewS2Sl+WL7TeEKX1EMHQbr2rP9j/gOxSWOmb4AqZ64yoeCKuEY1G
      CTbFh4MECOeWYqZXiNu4HC3rGJ03JcnaJzfas3zW3rkovKT4ekAa+hSCNmbb35hI
      0mQnHytbAoGBALuZw83Lkiy0vpV4szu/plQngRpriYsqekjWJCt1MHu4eo7LVUw2
      /REEaJlcHsjul2bSNyxjAPeWTvHKwtNfIYZHJm93V4p6LuP9Imyy7UTvZEWhePOA
      npb4o+L1k20W2l9jTWr1kLsnXz7M/HKMdySWPJXn2y5No1VGfL+9reTm
      -----END RSA PRIVATE KEY-----

  etcd:
    machines:
      - 0.etcd.private.<%= deployment_name %>.microbosh

  etcd_metrics_server:
    nats:
      username: nats
      password: "<%= common_password %>"
      port: 4222
      machines:
        - 0.nats.private.<%= deployment_name %>.microbosh

  blobstore:
    port: 80
    secure_link:
      secret: "<%= common_password %>"
    admin_users:
      - username: admin
        password: "<%= common_password %>"

  external_host: mysql.internal.<%= root_domain %>
  proxy:
    api_username: admin
    api_password: "<%= common_password %>"
    proxy_ips:
      - 0.mysql-proxy.private.<%= deployment_name %>.microbosh
  cluster_ips:
    - 0.mysql.private.<%= deployment_name %>.microbosh
  admin_password: "<%= common_password %>"
  database_startup_timeout: 1200
  innodb_buffer_pool_size: 2147483648
  max_connections: 1500
  seeded_databases:
    - name: cc_db
      username: cc_admin
      password: "<%= common_password %>"
    - name: uaa_db
      username: uaa_admin
      password: "<%= common_password %>"
    - name: console_db
      username: console_admin
      password: "<%= common_password %>"
    - name: app_usage_service_db
      username: appusage_admin
      password: "<%= common_password %>"
    - name: notifications_db
      username: notifications_admin
      password: "<%= common_password %>"
    - name: autoscale_db
      username: autoscale_admin
      password: "<%= common_password %>"

  request_timeout_in_seconds: 900

  router:
    enable_routing_api: false
    secure_cookies: false
    status:
      user: router_status
      password: "<%= common_password %>"
    enable_ssl: true
    ssl_cert: *ssl_cert
    ssl_key: *ssl_key
    servers:
      z1:
        - 0.router.public.<%= deployment_name %>.microbosh
      z2: []

  domain: <%= root_domain %>
  system_domain: <%= root_domain %>
  system_domain_organization: system
  app_domains:
    - <%= root_domain %>
  support_address: https://support.pivotal.io

  ccdb:
    address: 0.mysql-proxy.private.<%= deployment_name %>.microbosh
    port: 3306
    db_scheme: mysql
    roles:
      - tag: admin
        name: cc_admin
        password: "<%= common_password %>"
    databases:
      - tag: cc
        name: cc_db
        citext: true

  cc:
    srv_api_uri: https://api.<%= root_domain %>
    allow_app_ssh_access: true
    default_to_diego_backend: true
    buildpacks:
      blobstore_type: webdav
      webdav_config:
        username: admin
        password: "<%= common_password %>"
        private_endpoint: http://blobstore.service.cf.internal
        public_endpoint: https://blobstore.<%= root_domain %>
        secret: "<%= common_password %>"
    droplets:
      blobstore_type: webdav
      webdav_config:
        username: admin
        password: "<%= common_password %>"
        private_endpoint: http://blobstore.service.cf.internal
        public_endpoint: https://blobstore.<%= root_domain %>
        secret: "<%= common_password %>"
    packages:
      blobstore_type: webdav
      webdav_config:
        username: admin
        password: "<%= common_password %>"
        private_endpoint: http://blobstore.service.cf.internal
        public_endpoint: https://blobstore.<%= root_domain %>
        secret: "<%= common_password %>"
    resource_pool:
      blobstore_type: webdav
      webdav_config:
        username: admin
        password: "<%= common_password %>"
        private_endpoint: http://blobstore.service.cf.internal
        public_endpoint: https://blobstore.<%= root_domain %>
        secret: "<%= common_password %>"
    service_name: cloud-controller-ng
    external_protocol: https
    bootstrap_admin_email: admin
    bulk_api_password: "<%= common_password %>"
    client_max_body_size: 1024M
    db_encryption_key: "<%= common_password %>"
    default_running_security_groups:
      - all_open
    default_staging_security_groups:
      - all_open
    disable_custom_buildpacks: false
    external_host: api
    install_buildpacks:
      - name: staticfile_buildpack
        package: staticfile-buildpack
      - name: java_buildpack_offline
        package: buildpack_java_offline
      - name: ruby_buildpack
        package: ruby-buildpack
      - name: nodejs_buildpack
        package: nodejs-buildpack
      - name: go_buildpack
        package: go-buildpack
      - name: python_buildpack
        package: python-buildpack
      - name: php_buildpack
        package: php-buildpack
      - name: binary_buildpack
        package: binary-buildpack
    internal_api_user: internal_api_user
    internal_api_password: "<%= common_password %>"
    logging_level: debug
    maximum_health_check_timeout: 600
    quota_definitions:
      default:
        memory_limit: 10240
        total_services: 100
        non_basic_services_allowed: true
        total_routes: 1000
        trial_db_allowed: true
      runaway:
        memory_limit: 102400
        total_services: -1
        total_routes: 1000
        non_basic_services_allowed: true
    security_group_definitions:
      - name: all_open
        rules:
          - protocol: all
            destination: 0.0.0.0-255.255.255.255
    stacks:
      - name: cflinuxfs2
        description: Cloud Foundry Linux-based filesystem
      - name: windows2012R2
        description: Microsoft Windows / .Net 64 bit
    staging_upload_user: staging_upload_user
    staging_upload_password: "<%= common_password %>"
    tasks_disabled: true
    uaa_resource_id: "cloud_controller,cloud_controller_service_permissions"
    min_cli_version: 6.7.0
    min_recommended_cli_version: 6.11.2

  uaadb:
    address: 0.mysql-proxy.private.<%= deployment_name %>.microbosh
    port: 3306
    db_scheme: mysql
    roles:
      - tag: admin
        name: uaa_admin
        password: "<%= common_password %>"
    databases:
      - tag: uaa
        name: uaa_db

  uaa:
    require_https: true
    ssl:
      port: -1
    ldap:
      profile_type: search-and-bind
      url:
      userDN:
      userPassword:
      searchBase:
      searchFilter: cn={0}
      sslCertificate: null
      sslCertificateAlias:
      mailAttributeName: mail
      enabled: false
      groups:
        profile_type: no-groups
    login:
      addnew: false
    catalina_opts: "-Xmx768m -XX:MaxPermSize=256m"
    url: https://uaa.<%= root_domain %>
    jwt:
      signing_key: |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEowIBAAKCAQEAwy9j/rrDXu1RrBm8iEeHiyk/wC9HYEqEsgdvgZSaUBGoz8YH
        mkgSOdl60vKSq3Q8FJp/HlFEkNtoOCXuauQvyR8qSlE6B/gHtGt3Hd6KdPUSKifW
        RchI9rwSXoAnFMhPDaOtL8wgYAE3GPUj/5bxezLMbqiwii3XbD3a1XS/ID6XQk+6
        cqLqf2AXiTHNbqyqvmPH1v/wrmD+T5UUIB9Ah3etiWMvW2QOG36B46a4ra7Bg+yD
        3gI5aJOG9wqo5ajILESCG00sL8m7Eat1j9/MxznzUdp5ZtpoC89m34QlKKpIny+B
        hVRmnSXmrTneAN0+JkHi/PWa9hWB1dR9XVIk0QIDAQABAoIBAEUQwdtjDrrKUvoI
        6VN3rBir8ej5UdJay/WK+APsJ2ZpuUg8FHidRAXAVNvMBeYxbQkFWjHKI+72FDy5
        /1FHiTkrk/VUJKqpM2C+HhotouSby1+rVQDATEEyb3WM90c9UevLnP6qxlHyXCKy
        q5hHOw+S/A+0FTPv4KhmgsbBVtf7byyI72FIpaEeehbss/U3oJFCK/wag2AXSpMB
        VFFj8xzUnPYIpqcO4c3Zg9j4ugWGyDyHFBO4BMGrC0vKlxPPCWUMG8K8Dz5mgJ3l
        zmwwUvqtR5/KLSXwnL2b5d6Hy5KpMc1RxNpxExjgATlhVQCw1erQ5XEgZZnjjDE/
        i6pxSJkCgYEA8gVcD0fz4xxjLaPPFyZskHoACe9SPhpWsJt0lmK73D9ugMUTyIXP
        BfQGuqcdq3XrNz3ZMekqCq9dikdr9FpYoV/ifI/xxrVUs4MbbACYpIijCzioF1wv
        q4ka6QjS6Tt9HHFFzHBvfc2y7Wgflw1oLIBL5S7duSiYEGIGfp134FcCgYEAznV+
        Xdhw6XkQtGgPM5QYNYvfH+4vqELOYAwtTd2esGCXE1jsubK0CufpVMxezfXOeLqc
        /rCN/lpdKmxkaJFW2aIWBMMmvU0tTrB4dDiLobs4OxRiym1tN9xQhqSqiwz7quHQ
        KR+w/GT/IHdNj61hyad5r80wmhawiCmOwJOYyxcCgYABkNdPof+J8J0TpoOoeq8p
        ICDv74RwsmrtKZRPhMQCYMauPpgqK/Ny7mk8u+gNO+4RpWzKTd/fwdKxGlUwd4Ur
        RhuJAsVlq7aokqiSwk46gkfLwsoTnJ0SVwi9iTkUGTZuAK2a7P9LqREHSC0sJQIP
        h6T2Dp+QmxqgwIGaQBqOcQKBgBofO5HcJM0liDuLPwEjp7x+qgh8NoNvkHUOlVzY
        wY9HaVYFVk5YkfcfSKJ2CTi99RXJZrvC0vRvsoH/nOSuHvMCUw7fMjOZZDYkldj+
        nowkCAVRmv5JwhvjQD0I8JsPVXhVgeTyIY6NqMoOzj1zjn/ZNMhNiey1GjjgKTOs
        eRSZAoGBALJD6QBxaTWgsW2oP1VOeMTOtfrKjMmk3yfgYlPt8LD6K/k7Ov1SC7Ef
        slTMpD+7xnTo4wmKCRAagwjq02ECJGj2//G/O44FgxOWsa3CO26WkVq5DqJj4gw2
        1EBokvb5V9J8s7SH4iaZ2itgPrz+cRjbBKye71AQZALCpvn2gMQA
        -----END RSA PRIVATE KEY-----
      verification_key: |
        -----BEGIN PUBLIC KEY-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwy9j/rrDXu1RrBm8iEeH
        iyk/wC9HYEqEsgdvgZSaUBGoz8YHmkgSOdl60vKSq3Q8FJp/HlFEkNtoOCXuauQv
        yR8qSlE6B/gHtGt3Hd6KdPUSKifWRchI9rwSXoAnFMhPDaOtL8wgYAE3GPUj/5bx
        ezLMbqiwii3XbD3a1XS/ID6XQk+6cqLqf2AXiTHNbqyqvmPH1v/wrmD+T5UUIB9A
        h3etiWMvW2QOG36B46a4ra7Bg+yD3gI5aJOG9wqo5ajILESCG00sL8m7Eat1j9/M
        xznzUdp5ZtpoC89m34QlKKpIny+BhVRmnSXmrTneAN0+JkHi/PWa9hWB1dR9XVIk
        0QIDAQAB
        -----END PUBLIC KEY-----
    cc:
      client_secret: "<%= common_password %>"
    admin:
      client_secret: "<%= common_password %>"
    proxy:
      servers:
        - 0.router.public.<%= deployment_name %>.microbosh
    clients:
      opentsdb-firehose-nozzle:
        access-token-validity: 1209600
        authorized-grant-types: "authorization_code,client_credentials,refresh_token"
        override: true
        secret: "<%= common_password %>"
        scope: "openid,oauth.approvals,doppler.firehose"
        authorities: "oauth.login,doppler.firehose"
      identity:
        id: identity
        secret: "<%= common_password %>"
        scope: "cloud_controller.admin,cloud_controller.read,cloud_controller.write,openid,zones.*.*,zones.*.*.*,zones.read,zones.write"
        resource_ids: none
        override: true
        authorized-grant-types: "authorization_code,client_credentials,refresh_token"
        autoapprove: true
        authorities: "scim.zones,zones.read,uaa.resource,zones.write,cloud_controller.admin"
        redirect-uri: "https://p-identity.<%= root_domain %>/dashboard/,https://p-identity.<%= root_domain %>/dashboard/*"
      login:
        id: login
        secret: "<%= common_password %>"
        override: true
        autoapprove: true
        authorities: "oauth.login,scim.write,clients.read,notifications.write,critical_notifications.write,emails.write,scim.userids,password.write"
        authorized-grant-types: "authorization_code,client_credentials,refresh_token"
        scope: "openid,oauth.approvals"
      portal:
        id: portal
        secret: "<%= common_password %>"
        override: true
        autoapprove: true
        authorities: "scim.write,scim.read,cloud_controller.read,cloud_controller.write,password.write,uaa.admin,uaa.resource,cloud_controller.admin,emails.write,notifications.write"
        authorized-grant-types: "authorization_code,client_credentials,password,implicit"
        scope: "openid,cloud_controller.read,cloud_controller.write,password.write,console.admin,console.support,cloud_controller.admin"
        access-token-validity: 1209600
        refresh-token-validity: 1209600
      cf:
        id: cf
        override: true
        autoapprove: true
        authorities: uaa.none
        authorized-grant-types: "implicit,password,refresh_token"
        scope: "cloud_controller.read,cloud_controller.write,openid,password.write,cloud_controller.admin,scim.read,scim.write,doppler.firehose,uaa.user"
        access-token-validity: 7200
        refresh-token-validity: 1209600
      autoscaling_service:
        id: autoscaling_service
        secret: "<%= common_password %>"
        override: true
        autoapprove: true
        authorities: "cloud_controller.write,cloud_controller.read,cloud_controller.admin,notifications.write,critical_notifications.write,emails.write"
        authorized-grant-types: "client_credentials,authorization_code,refresh_token"
        scope: "openid,cloud_controller.permissions,cloud_controller.read,cloud_controller.write"
        access-token-validity: 3600
      system_passwords:
        id: system_passwords
        secret: "<%= common_password %>"
        override: true
        autoapprove: true
        authorities: "uaa.admin,scim.read,scim.write,password.write"
        authorized-grant-types: "client_credentials"
      cc-service-dashboards:
        id: cc-service-dashboards
        secret: "<%= common_password %>"
        override: true
        authorities: "clients.read,clients.write,clients.admin"
        authorized-grant-types: "client_credentials"
        scope: "cloud_controller.write,openid,cloud_controller.read,cloud_controller_service_permissions.read"
      doppler:
        id: doppler
        secret: "<%= common_password %>"
        authorities: "uaa.resource"
      gorouter:
        id: gorouter
        secret: "<%= common_password %>"
        authorities: "clients.read,clients.write,clients.admin,routing.routes.write,routing.routes.read"
        authorized-grant-types: "client_credentials,refresh_token"
        scope: "openid,cloud_controller_service_permissions.read"
      notifications:
        id: notifications
        secret: "<%= common_password %>"
        authorities: "cloud_controller.admin,scim.read,notifications.write,critical_notifications.write,emails.write"
        authorized-grant-types: "client_credentials"
      notifications_template:
        id: notifications_template
        secret: "<%= common_password %>"
        scope: "openid,clients.read,clients.write,clients.secret"
        authorities: "clients.read,clients.write,clients.secret,notification_templates.write,notification_templates.read,notifications.manage"
        authorized-grant-types: "client_credentials"
      notifications_ui_client:
        id: notifications_ui_client
        secret: "<%= common_password %>"
        scope: "notification_preferences.read,notification_preferences.write,openid"
        authorized-grant-types: "authorization_code,client_credentials,refresh_token"
        authorities: "notification_preferences.admin"
        autoapprove: true
        override: true
        redirect-uri: "https://notifications-ui.<%= root_domain %>/sessions/create"
      cloud_controller_username_lookup:
        id: cloud_controller_username_lookup
        secret: "<%= common_password %>"
        authorized-grant-types: "client_credentials"
        authorities: "scim.userids"
      cc_routing:
        authorities: "routing.router_groups.read"
        authorized-grant-types: "client_credentials"
        secret: "<%= common_password %>"
      ssh-proxy:
        authorized-grant-types: authorization_code
        autoapprove: true
        override: true
        redirect-uri: "/login"
        scope: "openid,cloud_controller.read,cloud_controller.write"
        secret: "<%= common_password %>"
      apps_metrics:
        id: apps_metrics
        secret: "<%= common_password %>"
        override: true
        authorized-grant-types: "authorization_code,refresh_token"
        redirect-uri: "https://apm.<%= root_domain %>,https://apm.<%= root_domain %>/,https://apm.<%= root_domain %>/*"
        scope: "cloud_controller.admin,apm.read"
        access-token-validity: 3600
        refresh-token-validity: 2592000
      apps_metrics_processing:
        id: apps_metrics_processing
        secret: "<%= common_password %>"
        override: true
        authorized-grant-types: "authorization_code,client_credentials,refresh_token"
        authorities: "oauth.login,doppler.firehose,cloud_controller.admin"
        scope: "openid,oauth.approvals,doppler.firehose,cloud_controller.admin"
        access-token-validity: 1209600

    scim:
      user:
        override: true
      userids_enabled: true
      users:
      - admin|<%= common_password %>|scim.write,scim.read,openid,cloud_controller.admin,dashboard.user,console.admin,console.support,doppler.firehose,notification_preferences.read,notification_preferences.write,notifications.manage,notification_templates.read,notification_templates.write,emails.write,notifications.write,zones.read,zones.write
      - push_apps_manager|<%= common_password %>|cloud_controller.admin
      - smoke_tests|<%= common_password %>|cloud_controller.admin
      - system_services|<%= common_password %>|cloud_controller.admin
      - system_verification|<%= common_password %>|scim.write,scim.read,openid,cloud_controller.admin,dashboard.user,console.admin,console.support

  login:
    url: https://login.<%= root_domain %>
    self_service_links_enabled: true
    asset_base_url: "/resources/pivotal"
    protocol: https
    tiles:
      - name: Pivotal Apps Manager
        login-link: "https://apps.<%= root_domain %>"
        image: "/resources/pivotal/images/dev-console-logo-gray.png"
        image-hover: "/resources/pivotal/images/dev-console-logo-teal.png"
    brand: pivotal
    links:
      home: https://apps.<%= root_domain %>
      passwd: https://login.<%= root_domain %>/forgot_password
      signup: https://apps.<%= root_domain %>/register
    uaa_base: https://uaa.<%= root_domain %>
    notifications:
      url: https://notifications.<%= root_domain %>
    saml:
      entityid: http://login.<%= root_domain %>
      serviceProviderKey: |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpQIBAAKCAQEA5rk+K3j9hS84jUC2/U5rpRSCCBQKsUf/V9syi6Zz67xu3CRn
        gT3Bwi9Z8Y1iypKf07ghve/1snBbx/RclH8boMbpXww4BzGea1xzNG1lpmMfIcpT
        OumI+7UvEC++dxFjH3PW7e8a6Inahb+dlXGiKym9oKSifbJmFHgVGoXewkypssx6
        UP0NA0OTDLpGhQUkHfvpqe7jGdxwFwatoSUmN/xT0U/UO6kuPQoHMyVREXpYkdFm
        RTGXkoQfqrdCHdWwmFv4VxSkAnQYxq9YD2D3N7oA/ob7eDaF7Qx35z+5syH92eyP
        4Sozx/LJgFXz4+r2R0GRlHWS2sLCuE++mgEDZwIDAQABAoIBAEC6Y3iqvuUodEMc
        jrnN0GFFuZ0ukjleK4KoWivXjNnryWY1SFx3yO4DfsZHlhmivPgWxlCVC2b+IqGc
        KoT2i/e1Fi+2K9nIz9rq2t8web4OPOOr8WGrtuR21jdCTbr1w8tFIl0qIXBvjEDN
        mxYcBRT65to0lemRrRW9Ap6oQ/BaLQ9y9s4e4fLSTQFEbpD0q6/7/0g9WX0KXseS
        rVnkwET0PXn2fobHHk6GKkQkh3UrCPL8tIAsJ2mYYNPUy1zvrrDRMbJnYZIO0Ig0
        NfNkH4UQvyAqzP6qPFuIltBO+XIDrSIBwuNb06j2ItcPy2HTPOP9L1D/YVuMIH2Z
        oDU3vTECgYEA/6WeK99EeyOPupA92Gw72bJdNyvT9XIZHb0DuTKClnQUWm0kuY9N
        dzUEoB78f/Y+FqQZ1GemVSb2sHf5BmsqQNwxf09KkN7kqPn8miQ+TqMMQFat+iFq
        In0lzrbqj7U59lI4pSdIwJ/gbhYyjl9JmRKtQn6VQ0E9V/X7SUs25WMCgYEA5wrQ
        QzwJKKvDjc5PJxhEj8dhjgmHF0gU6q1PcDuzb0yoMquY1+75UMDWPwezXNIEnfap
        Lgxt/2xOqSU+EDtpv/vhz+RE4bChFWvHg4c/Ba9976YtiIuGJLNOW/vQzzIo+yuZ
        cxQfrJ9RC0gEOrG7+eKKSygNADjXtIfD9h4V2y0CgYEArWsCzg4JnWK1OEBqw6pA
        O2AEXc2sXh7FLOgwY2wBK+CYgfLx67JrQUdE2P3MGV3IJoGxR+X77l2dEH6B/jmq
        Ew+LwCngkj+xa3MRSNr3LU7rm6VxJXGPVtAAWqa4nT25kP+bj2UDtC+ABg2mw++d
        tGn4AFhwFoxl+YpSqRiNp7MCgYEA1xC0znE7IVXKId1SxtSLNb9l6v6pdp2Nguoz
        EQkxvUABLbGYBCEaiPYIOQHlD1kcHSK3VvsRBXt/OWpGfHuhs6k3CPq2t9NgDv2V
        6bRikNtMAmGQ7xLZmp4iKfOc6tIJXcy2+W1ZEqn2mea+sRgzH6emDdHJUFSZTh42
        5ooY1D0CgYEAqwka0ru0mrNGTzqucZTCwZiopT5f2pQ+3ckyaUwR/JpyvNdZM2dz
        b2jShQbcHdGo11hZihiB8nXcvzCku16UiMzVqBcHf3f6/aOBule0d35VVTGHPlHw
        vL5HUzkU+TXTJy80NwPfsfs5qe+aq+V5nogCvgG8/JCeAsliFll3G+U=
        -----END RSA PRIVATE KEY-----
      serviceProviderCertificate: |
        -----BEGIN CERTIFICATE-----
        MIIDSDCCAjCgAwIBAgIVAIwM1IbvbFeTSGt3ojzxlf7RgvNEMA0GCSqGSIb3DQEB
        BQUAMB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMB4XDTE1MTExODIw
        NDUwOVoXDTE3MTExNzIwNDUwOVowSjELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bp
        dm90YWwxKTAnBgNVBAMMIHNlcnZpY2VfcHJvdmlkZXJfa2V5X2NyZWRlbnRpYWxz
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5rk+K3j9hS84jUC2/U5r
        pRSCCBQKsUf/V9syi6Zz67xu3CRngT3Bwi9Z8Y1iypKf07ghve/1snBbx/RclH8b
        oMbpXww4BzGea1xzNG1lpmMfIcpTOumI+7UvEC++dxFjH3PW7e8a6Inahb+dlXGi
        Kym9oKSifbJmFHgVGoXewkypssx6UP0NA0OTDLpGhQUkHfvpqe7jGdxwFwatoSUm
        N/xT0U/UO6kuPQoHMyVREXpYkdFmRTGXkoQfqrdCHdWwmFv4VxSkAnQYxq9YD2D3
        N7oA/ob7eDaF7Qx35z+5syH92eyP4Sozx/LJgFXz4+r2R0GRlHWS2sLCuE++mgED
        ZwIDAQABo1AwTjAOBgNVHQ8BAf8EBAMCB4AwHQYDVR0OBBYEFD/IwMpw+esmLqgf
        07TE3VLc7nYlMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcDATANBgkqhkiG
        9w0BAQUFAAOCAQEAElm/s3eXlKuu2uXYXjGdessKRQjVSecUWIv1ctMfu2Jer9Mf
        YgucYPt85wDUPHUdnSsHfX1keNOHikVN3bHMEpDZkOdyLZDhmZsroI1HqT3Fs0t2
        slaR0gdSGPXmxcIroMdvNKFSNcAh9nI7yUuVgBlTZP5Z8AFgYb7hT1aDb6+XjXcp
        i98KTKC4PsvPUYtWcXQOzGjKWml9gLstahnAVEfD32hV94ddGQKPzKClrGPJ4g2L
        sfN+x6NA5GfbIQyVrQdSPagix9SCiiSQcq2L4wpWj2waY64vubZJtcw18jhtCdi+
        YbfjzHF6hnd7LH5t6vPL6d6SeOY/ymuVngyVWw==
        -----END CERTIFICATE-----
      providers:
        '':
          nameID: urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress
          idpMetadataXML:
          idpMetadataURL:
          showSamlLoginLink: true
          linkText:
          metadataTrustCheck: false
    logout:
      redirect:
        parameter:
          disable: false
          whitelist:
            - "https://console.<%= root_domain %>/"
            - "https://apps.<%= root_domain %>/"
        url: "/login"

  diego:
    ssl:
      skip_cert_verify: true
    executor:
      post_setup_hook: sh -c "rm -f /home/vcap/app/.java-buildpack.log /home/vcap/app/**/.java-buildpack.log"
      post_setup_user: "root"
    bbs:
      ca_cert: &bbs_ca_cert |
        -----BEGIN CERTIFICATE-----
        MIIC+zCCAeOgAwIBAgIBADANBgkqhkiG9w0BAQUFADAfMQswCQYDVQQGEwJVUzEQ
        MA4GA1UECgwHUGl2b3RhbDAeFw0xNTExMTgyMDI3MTZaFw0xOTExMTkxOTQ3MTZa
        MB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMIIBIjANBgkqhkiG9w0B
        AQEFAAOCAQ8AMIIBCgKCAQEAwAI/I5GhhpWpJdSUM5rrOWpoKvL9ylINZOxs1kcm
        2g35sipVE/+Vg+8tb3A7sOKLTa/+/yWNaY3o1sv+eIxjsHtIt7Tj1gkFZWpHZ6RX
        jkzyrPCTqaMCrcOjarRRdsI5ExA4CX8qsFFQrYv5Xrv0o0XfctXwAVkc68NxyHov
        v0x0h2ULvp1iff5QyT183LDjOUiiK3gqSrj6BpQy6yp/e/X/aZatQEjvaLuWqmU3
        Zv6WLMA36vPVr4JoZxu9beD4QW+5PBsmGz9yrpaB7jOnFwhU0zvtv/vSZxdrpLmY
        b4ZwXHMR2oY045OdJWI6bwXuOSofPj95aItjKVn5Swuy3QIDAQABo0IwQDAdBgNV
        HQ4EFgQUXMQUYHcIWzZ6aUtbc4Yv/4xGfjswDwYDVR0TAQH/BAUwAwEB/zAOBgNV
        HQ8BAf8EBAMCAQYwDQYJKoZIhvcNAQEFBQADggEBAEhU5Gl+ywoJPRyEvXcrlGdS
        fbvzIQyLS6C6GnXpDTqOLIXtTqrUJkqVH6GXBQcBShtXzfvW5Rua4HDEKj6wPF4j
        5QziIE0UrdJdFMupA3cPE449gITGFG20/O3xXGmeWzIijbFgKOEYyQIkExR3lcqb
        czPN1MMNB6pI+HZVk0sn2QPD3p5kTnJRF0/wvq1rUbQ1ddW1BroCDywTecAgGK1X
        k2OIFEg0Js7aX9/M/jLnNjTdjc5RUE45b0chPQJ9lv2Ub4jqItqtrZhy77a0e5Pb
        ucAbKSizVP/2rml1JzLmL6V4jJtI6RWrUHuCIQDCFBvqN6cHqoQW8x++UuuPe44=
        -----END CERTIFICATE-----
      server_cert: &bbs_server_cert |
        -----BEGIN CERTIFICATE-----
        MIIDgDCCAmigAwIBAgIVAIsjZkDe5vJ9bcs1M7uxE5+vCuMfMA0GCSqGSIb3DQEB
        BQUAMB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMB4XDTE1MTExODIw
        NDUwOFoXDTE3MTExNzIwNDUwOFowQTELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bp
        dm90YWwxIDAeBgNVBAMMF2Jicy5zZXJ2aWNlLmNmLmludGVybmFsMIIBIjANBgkq
        hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsT6zQvqbTWPZsa5UN2zN28Y12R0hNJI9
        WWaCHn+unfTZ8jKvFXim/g+oza5ZlDm1TunBDi2Uw913jJcJncX1YFs5HXzAhpVv
        3erRNJ1CPSa8m0XQkDO44qYRwfvUN45P3aHRZnzGeys8jBDvV/epMKXMxeVP/8XZ
        4uun3kKNYKLAgEKMZIQtaWiAB7PKKtrCXASlnMdv+gF5yhvnAVLUqlvbJ+3EyMgX
        C1ARCLyvF5MoP5eLPIh9mdzC+Co75TKS7fIgso9hZnHxRnZ58xl8KITm82QUbyhv
        Njr/qJFddFVgwX9AFzuDnU9qKEQR9udGywfVwIMq1h+5Jp7C+3P66wIDAQABo4GQ
        MIGNMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQUd2OADLKI8P4RBvWTFKi8TdHP
        6MQwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMD0GA1UdEQQ2MDSCF2Ji
        cy5zZXJ2aWNlLmNmLmludGVybmFsghkqLmJicy5zZXJ2aWNlLmNmLmludGVybmFs
        MA0GCSqGSIb3DQEBBQUAA4IBAQCsYfEaQSfXdbbpNknOkXIlO4jmpgd3kuZjiZcb
        e8t67mF3C39+ts88mI4SU/GtqvmujpGALGjRi0iKv5POGCRePFPaIPknTRCTCQhq
        qgI6mLA5MKLg/lqP9J8XzHFNvbDrstHgFisB7CWu5wHQdo9XPU13OuxUWy09y0MH
        YHPT8l9ustMDHNWUB9UmlXDUvvOoH/UKjdlCIRifVlak695MKaJEOn9OWZgP1p2G
        BkUfFeY2LfjufK90wf0awgKIR1CBwuaOBaM/tpDHIf7HMdZOSdEw3TP+2lQ37ZQ5
        OeCn1wWamr6v7vdexatAZJNPdCVTUewiOkFc2y4gp0as7Txk
        -----END CERTIFICATE-----
      server_key: &bbs_server_key |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpAIBAAKCAQEAsT6zQvqbTWPZsa5UN2zN28Y12R0hNJI9WWaCHn+unfTZ8jKv
        FXim/g+oza5ZlDm1TunBDi2Uw913jJcJncX1YFs5HXzAhpVv3erRNJ1CPSa8m0XQ
        kDO44qYRwfvUN45P3aHRZnzGeys8jBDvV/epMKXMxeVP/8XZ4uun3kKNYKLAgEKM
        ZIQtaWiAB7PKKtrCXASlnMdv+gF5yhvnAVLUqlvbJ+3EyMgXC1ARCLyvF5MoP5eL
        PIh9mdzC+Co75TKS7fIgso9hZnHxRnZ58xl8KITm82QUbyhvNjr/qJFddFVgwX9A
        FzuDnU9qKEQR9udGywfVwIMq1h+5Jp7C+3P66wIDAQABAoIBAExL9DiJzh5jNAuD
        QmdVY8wOJ5HdMzUBGn2IXcypI86E3uieHrX8aM4GiaB4Q8FFkiF1CBCFWHtzswmG
        3rHWzAh9XDmwQOPuIeiCMyoV47SVHy0rwVrBmP2fhRdewvxjO0fpZ01Zusq8UuTs
        SUsxpdf2Fw685lHwphlDXdCUD22gCU2Luf/X6N81weCR2ZBiE9Vs7+NQgSZXfgg7
        n+GX8MZIU6J4KZmhRWuOeSzET+gwUYFEVjGyMf+5zAAAymHXNGk9WmuDpWg4VV3Z
        lrORqT+gamHKAMulnAFaugC0Oudy9a3EynGOSP7bkp4+6QCu1n2E8vszVwM4DIfV
        tqTQIVECgYEA6iPBQjfep02Bnn16x3qR/1e3CjfBu+2dfyXYFMxGe/4udhHZ4Vb7
        MaYpxQy2MKfP4NJpQwRRXsuJCx5IDydkTldIRK2qOrzHBS34GgFwDUZqwPmp4LWE
        HggmtEhNaurYDqvRqOEZFqBq3WAQGd5JYdo9hGtba9yMQVv/AHQNI7kCgYEAwcsW
        GNvI5hRdRl9dzmiQFc7IswyrbR1YS/zctPL6hVEkKriYI6OlyzCJaSEnWLD4Tc9C
        V3I+OCbVDNE1z4p1AAI5s7h4I9wmvPYQxK2lNxTncv0bz5UatwXtWkW9Fgxj20QW
        +sz5DNoBXbuHvg88Nw+z+xsKFrOswG8Ifj0cbcMCgYEAsvMa3OpokQPq4mBS+60R
        cs/uhK+ysVhdfHVHHjY2VMQjbHgeR1y8Zejymbkqcit/9Pu8Gc1uB36WQlolhvd7
        cWjCQkNdDMGFds74hZ+9rVe5db4beTQiQvXF5xovmVzePvBRMLrB+womQwYNqEe9
        XD15sQCAggKxa67NSeJovHkCgYEAjpP1QPrK9wP6kCDv6kGh6HmHzbu/j/rsEJQM
        aZDu4hENs+S2AlqPS0v9fPxob2dceBrJq36g6j0fuFtf5L7wT75TZ7eLpI5/bbz4
        H0vGZx0ZH8+6m2IPEqLouubeNA+PlC2nXoRZo6vtH2Iuf5XD7pq+Bzwgkw1ERxwp
        un8JoHMCgYBH/8MBBE67TScut2KLv8gQUPiQLkbNMzXR3si1nFV0sYOl+28O4zvJ
        EZrD1nmDRNTI/bjCJu2eCOeUuRgzGy2VjCwuQuPix+mRp4miIHCIc5bV2I6Vijsy
        xL9u7xB9xLBCCtgdbNM0Czyy1UgHQH1jMN6RglCNsE2Z8QDC+TbqCA==
        -----END RSA PRIVATE KEY-----
      client_cert: &bbs_client_cert |
        -----BEGIN CERTIFICATE-----
        MIIDNjCCAh6gAwIBAgIUIHzJ2ThG0gBgTOmgs0sVplDufRcwDQYJKoZIhvcNAQEF
        BQAwHzELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bpdm90YWwwHhcNMTUxMTE4MjA0
        NTA4WhcNMTcxMTE3MjA0NTA4WjA5MQswCQYDVQQGEwJVUzEQMA4GA1UECgwHUGl2
        b3RhbDEYMBYGA1UEAwwPYmJzX2NsaWVudF9jZXJ0MIIBIjANBgkqhkiG9w0BAQEF
        AAOCAQ8AMIIBCgKCAQEAs+iOelSp8GAZryCXc77SUgj/x8MJJIJ9TM71Gp+DHjZM
        RLg27o9iTCEaCZky8S1qBQjG2Q90iT37Zsf3SRpDjm6ZZab0Pg/d50s0pF4rQy8s
        6xhhxw9iXbyb6YwwpUexTKutTSyaKXM12HQCd3DeNB/J6SG9tAbFVzOMOf+wE6w9
        wByAkE7strCfwibUjrCTaSQzzRquKc50iuYTMFAWtLrD35HY/NXTtwADys9ioyhh
        u23wyRDHqkzHR0jPmEZJHGL0sxon6zbVn1SVay+wsqCW9zThjO0bSNDA2219gSiP
        aSJvEVPWQoWJq0SyPFaVux/l2V6wWBsfMwltBe/OmwIDAQABo1AwTjAOBgNVHQ8B
        Af8EBAMCB4AwHQYDVR0OBBYEFJB85TezKxTIYatEsKc3PC+0RfrtMB0GA1UdJQQW
        MBQGCCsGAQUFBwMCBggrBgEFBQcDATANBgkqhkiG9w0BAQUFAAOCAQEAAxRgO0qE
        wyUHIVK5RwKpA0KLZaFZ/WRMyzzEGJPv+dsv6MUxW28jdrACdvgYL8EW40jI8oxH
        Ck7S4hnKxx3wZda+FY+jg9v44XDfkyRB3daoJb2+ygOvQa4L/YhTvyTe8ra3yol1
        /zSaPLIyc0r/25jOyVjIiJqnjxkgg14a3mJSUT6gGpsuCLvP+1a4Y38y5fO5A9hE
        WT7GqQcu/Gf9ZN7yjhj6cAwV0YPEOZ2JSIre9W+LPtwyqnT0gCjv7Qke+gDznSKZ
        3LV4CuSwtMPsiAgCSJUWfvAg4CceqfP8+BmEzlKt3Y+tbO2qMUGxPto8rTvJPePH
        2fki7dXTdC7uNA==
        -----END CERTIFICATE-----
      client_key: &bbs_client_key |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEowIBAAKCAQEAs+iOelSp8GAZryCXc77SUgj/x8MJJIJ9TM71Gp+DHjZMRLg2
        7o9iTCEaCZky8S1qBQjG2Q90iT37Zsf3SRpDjm6ZZab0Pg/d50s0pF4rQy8s6xhh
        xw9iXbyb6YwwpUexTKutTSyaKXM12HQCd3DeNB/J6SG9tAbFVzOMOf+wE6w9wByA
        kE7strCfwibUjrCTaSQzzRquKc50iuYTMFAWtLrD35HY/NXTtwADys9ioyhhu23w
        yRDHqkzHR0jPmEZJHGL0sxon6zbVn1SVay+wsqCW9zThjO0bSNDA2219gSiPaSJv
        EVPWQoWJq0SyPFaVux/l2V6wWBsfMwltBe/OmwIDAQABAoIBACSlzNAyiuOCT/kS
        pIdZabJ4TtI8cpJTWn7Y8ajYsXboDKU6+UWjQ5zKaWlnIa9rVttrrEXvFggW7i1D
        sqXbicNr2CeS2NIDnWpOMY0B+cIXzAif0Nsh0SHTF9d9TTN95Sn/FrBP05957pAH
        IbF+9mSbzR+GVgRkFLLstzXhVdbLudkCmp+mxir8eN4DsyIOMFlw5eDSWWvI7oSb
        r01++Y/LgR/r2dQOf45bTfSMHefDH0cfAyKeVCTuwRKAaJJFObaWxqDlQCnjvV7F
        hHagq7Cwak66HRWhSRBRwAQ3iI7IX+m4AicCgeIUIOBtSxzE4h2PdCsv26yUHR3D
        tD2ReVECgYEA3JxakFd/bYgnJYByHvZfdHEewtsSREuN27q1CB1ew0P5pBfZgK62
        EO1UKBIUEJ924DegCwdZPLrcm1FOdRdm86cIyBqnhrBhCBKqu22fhlV6fUBYEx4A
        TjBMs5WJDhdU9dNREkF5/S7J6HgUxtIvdIQjPbJpd+c/PJJy/ij3XT8CgYEA0MS2
        ZsNjWPMKa4UoAxIi0oB+CHrUjpGKnE/maW+OvakwLI/50RPcbA6wQ0ZnIQC4d078
        6YW0zhqa+PeFoKy2c2o4hB8HCC7o1vlptATnrcUyKYgkQoenrWyu2KeVakSlQd9N
        R9BWPrLkzS3aXW8jgffxxSJRGHJlpta5mg/BC6UCgYBSB+2A+JgQcW0k+7Lzomby
        FFH84JrVPEbeanmAL/OZpgAArUGaINzgRG9jiv1dBP6d9vESyMO82jrHoh8LWQ1W
        EkkopwieA53A87f6g5OqzsQCKNfXG/O/HySWLkdNLw3PbqkZobErnKdFQslu+J7e
        s3erLFkdVaZk7ovFyBPa3wKBgQDE5JGmr6YV8Pol16qZ4tPmtfqnorivUUJqE80a
        KXV1GIjvrkYM0u9zFhNVD6QZ8yUGmP9cepbAP0Vjg4aKt/lHNqngqaanKB6/CPGR
        L4MVV0Ls+pJAENKqdDMe8Eaxt9YoHyMylKGSdoPlotYsgrH5VM+3fZsANHv8cs0P
        KMaHZQKBgFjsMed30+ufTbU0tkNaFkp+LAXJKreFoAOWNRZTiwCItr97CaV3pBlH
        04Nyjgm+iyKYaxOhx0Rtbmex0CarRwLYaf9b/AhCaobDMjtkFNmyVnFaty736UpN
        4sP6R9yPRjNRH8WwmiU6d37D59v6Suac2jnNgkaALdAwtuUUuFyV
        -----END RSA PRIVATE KEY-----
      active_key_label: key1
      encryption_keys:
        - label: key1
          passphrase: "<%= common_password %>"
      auctioneer:
        api_url: http://auctioneer.service.cf.internal:9016
      etcd:
        machines:
          - etcd.service.cf.internal
        ca_cert: *etcd_ca_cert
        server_cert: *etcd_server_cert
        server_key: *etcd_server_key
        client_cert: *etcd_client_cert
        client_key: *etcd_client_key
        peer_ca_cert: *etcd_peer_ca_cert
        peer_cert: *etcd_peer_cert
        peer_key: *etcd_peer_key

    auctioneer:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key

    cc_uploader:
      cc:
        job_polling_interval_in_seconds: 25
        basic_auth_username: internal_api_user
        basic_auth_password: "<%= common_password %>"
        external_port: 9022
        staging_upload_user: staging_upload_user
        staging_upload_password: "<%= common_password %>"

    converger:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key

    file_server:
      cc:
        job_polling_interval_in_seconds: 25
        basic_auth_username: internal_api_user
        basic_auth_password: "<%= common_password %>"
        external_port: 9022
        staging_upload_user: staging_upload_user
        staging_upload_password: "<%= common_password %>"

    nsync:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key
      cc:
        base_url: https://api.<%= root_domain %>
        basic_auth_username: internal_api_user
        basic_auth_password: "<%= common_password %>"
        staging_upload_user: staging_upload_user
        staging_upload_password: "<%= common_password %>"

    rep:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key
      zone: default

    route_emitter:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key
      nats:
        user: nats
        password: "<%= common_password %>"
        port: 4222
        machines:
          - 0.nats.private.<%= deployment_name %>.microbosh

    ssh_proxy:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key
      enable_cf_auth: true
      enable_diego_auth: false
      diego_credentials: ""
      cc:
        external_port: 9022
      uaa_token_url: https://uaa.<%= root_domain %>/oauth/token
      uaa_secret: "<%= common_password %>"
      host_key: |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpQIBAAKCAQEA0A8RpzkksPj5cHjk02Gc2UtAlhYLoUFIeP+TS7vKjcm8dGLq
        481fhvyttoHIMF3zdkeuUTAHeFC8Vpy3FFostpljTBuvccV7//b5m6xOp7HS8+R7
        sgohPoQOytlRuymfEqAYutFChmWnDaq0hko/dILXwmAqBiKX/xMv/w2Bq91FlCxX
        +agRFo3t6VNFHIUw3Stp0MBNPE786WNA1oXB0YefjRvTgn+NWayUmRg8kpCiK3nl
        m7HxgYPsfFtJU0cTMLEdIMJQg9bbh6ThRbQGNCMdfywD/DXT42Ec2o1cmaaPwJPq
        Nu4ACbKbYbkls4QGHeaWlWzHzGVeDrnhOxGtkwIDAQABAoIBAQDOelXrnZMjKkLp
        8qAsgw/UuZDEIeayxoX0xrZYD2rqIY2r90rifjtSTErc95lDHsnx1RtSqRaQuZbf
        YbFzOjZrlHft3P/VKcZwdJqsemiolZojvtlfDByH3SiM+PTaiGi8ZDOGmwupMxKB
        RqrXJrIon30eAq9R3Vz4oAMe3DmW4zwCUV2KskkAw72TuVI145dB/ToaOl4wQDl/
        I7+QBhlDOp93Jzq8GeBoSN5LTWuggj4LCAElioky1ZK6tR2knEFrdzBg0eyvCKyF
        xxI5a0dGKld42qAhKTwZE/RwjMAf2Ft7KaQdfqW5NqH5qnvyfL7hGPLMoF9vl4eg
        uE/pDcY5AoGBAOldPz7X+fGzmB1BJ1sm4ycS8d/rifFM6Mvj2jV7iHEdeFl/TU9+
        Z6d17x2a0I4p+UcLbNbwRoOFTaKVoqtLrXVgm1qk9N9rBKcEMEXIOfxmaq40FA/i
        a+uhRoSxcRzNlX/f46z7tjqc1A5/M1zldISHH+i0+EjIj+x5U8hoMDe9AoGBAOQ9
        dGXxvjr1cHJktAhJTKrnbsIf693mF7XpKbeVlWixTgo224RecrOrFC/G2VpJWNQu
        zKRvoayOUSqEgxvMChYh9BdGaHqVR3ieOPq54MycejfeS6JzfK8Tx5uIJpIpX7pF
        +cGuOEYu+wsDFow8gDkNG5TPNtpHC/c2lBJzI+ePAoGBAK5UaHDL6v3yigogqAPi
        EwMXlfUPAedu6uGVf2dAt3a46zUAcoKWDVz+LvjQtEffd0bpdA9FQ4fwx0RTwEdy
        q0vqNWQLoppcWgdii6U1pIu2/q7QXMRZAwHtYr6xx6wasDnsySpqh4FVstx5jacy
        Ck8Omnm+51OH8GxZXotxucOJAoGAE1QY/WEhiQCsCyP4ExOSCI8c1Be788i+jUs3
        mzJxurH5N+g5YtZUxF5ikUE3uuunOCDWd750ZJaQzRb3u2zmFcW+VBJEWs01hkNv
        89u16938g6qxoQpCrtjv+H3pNkuGrdGrOvm0Dk2AOQiD6lBdU3eGtG1v6cBGhSL8
        GyvhCIUCgYEA43A8tcSZXhWyXOmHtWqlhzHPUlDqfrNZfZOWwmLrjyyrEEs1gLWV
        PqSyfJffc3P5cKNqetMzKCqSQEHES/0+s0GlY1LZjyrDmfGyPpWRdKsBE2ALT9z7
        0EKwlbbvTYGTjwez+QgBXMwGbZTukZkClcCB1moHSf6ebapvw/VmO20=
        -----END RSA PRIVATE KEY-----
    stager:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key
      cc:
        basic_auth_username: internal_api_user
        basic_auth_password: "<%= common_password %>"
        external_port: 9022
        staging_upload_user: staging_upload_user
        staging_upload_password: "<%= common_password %>"

    tps:
      bbs:
        api_location: bbs.service.cf.internal:8889
        ca_cert: *bbs_ca_cert
        server_cert: *bbs_server_cert
        server_key: *bbs_server_key
        client_cert: *bbs_client_cert
        client_key: *bbs_client_key
      cc:
        basic_auth_username: internal_api_user
        basic_auth_password: "<%= common_password %>"
        external_port: 9022
        staging_upload_user: staging_upload_user
        staging_upload_password: "<%= common_password %>"
      traffic_controller_url: wss://doppler.<%= root_domain %>:443

  app_ssh:
    host_key_fingerprint: 13:a8:cf:0a:f4:ba:5d:51:52:04:08:6d:f9:6b:67:2e

  garden:
    allow_host_access: false
    persistent_image_list:
      - "/var/vcap/packages/rootfs_cflinuxfs2/rootfs"
    enable_graph_cleanup: true
    network_pool: 10.254.0.0/22
    deny_networks:
      - 0.0.0.0/0

  loggregator:
    etcd:
      machines:
        - 0.etcd.private.<%= deployment_name %>.microbosh

  loggregator_endpoint:
    shared_secret: "<%= common_password %>"

  logger_endpoint:
    port: 443

  doppler:
    port: 443
    zone: default
    status:
      user: doppler
      password: "<%= common_password %>"
      port: 5768
    message_drain_buffer_size: 100
    uaa_client_id: doppler

  doppler_endpoint:
    shared_secret: "<%= common_password %>"

  traffic_controller:
    zone: default

  smoke_tests:
    api: https://api.<%= root_domain %>
    apps_domain: <%= root_domain %>
    user: smoke_tests
    password: "<%= common_password %>"
    org: CF_SMOKE_TEST_ORG
    space: CF_SMOKE_TEST_SPACE
    skip_ssl_validation: true
    use_existing_org: false
    use_existing_space: false

  acceptance_tests:
    api: https://api.<%= root_domain %>
    apps_domain: <%= root_domain %>
    admin_user: admin
    admin_password: "<%= common_password %>"
    include_logging: true
    include_internet_dependent: true
    include_operator: true
    include_services: true
    include_security_groups: false
    java_buildpack_name: java_buildpack_offline
    nodes: 1
    run_security_groups_tests: false
    run_ssh_tests: true
    skip_diego_unsupported_tests: true
    skip_docker_tests: true
    skip_regex: lucid64
    skip_ssl_validation: true

  cf:
    api_url: https://api.<%= root_domain %>
    admin_username: push_apps_manager
    admin_password: "<%= common_password %>"
    system_domain: <%= root_domain %>

  services:
    authentication:
      CF_CLIENT_ID: portal
      CF_CLIENT_SECRET: "<%= common_password %>"
      CF_LOGIN_SERVER_URL: https://login.<%= root_domain %>
      CF_UAA_SERVER_URL: https://uaa.<%= root_domain %>

EOF

sed -i s#{{DIRECTOR_UUID}}#`bosh status --uuid 2>/dev/null`# cloudfoundry.yml
sed -i s#{{REGION}}#$region# cloudfoundry.yml
address=`gcloud compute addresses describe cf | grep ^address: | cut -f2 -d' '`
sed -i s#{{VIP_IP}}#${address}# cloudfoundry.yml

cf_ip=`gcloud compute addresses describe cf | grep ^address: | cut -f2 -d' '`
cf_domain="${cf_ip}.xip.io"

sed -i s#{{ROOT_DOMAIN}}#${cf_domain}# cloudfoundry.yml

echo "Setting bosh deployment file"
/usr/local/bin/bosh deployment cloudfoundry.yml

echo "Starting to deploy cloudfoundry"
/usr/local/bin/bosh deploy

echo "cloudfoundry deployment successful"
echo "Use CF CLI to login ...."
echo "cf login -a https://api.${cf_domain} -u admin -p c1oudc0w --skip-ssl-validation"
