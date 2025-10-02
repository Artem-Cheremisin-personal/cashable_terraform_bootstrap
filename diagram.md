```mermaid
graph TD
    subgraph "External Users"
        User["External User"]
        Admin["Remote Admin/Developer"]
    end

    subgraph "AWS Cloud (eu-central-1)"
        subgraph "VPC (192.168.0.0/16)"
            subgraph "Public Subnets"
                NginxALB("nginx_lb - Public ALB")
                ClientVPN("Client VPN Endpoint")
            end

            subgraph "Private NGINX Subnets"
                NginxASG("NGINX Instances - ASG")
            end

            subgraph "Private App Subnets"
                AppALB("app_lb - Internal ALB")
                AppASG("Flask App Instances - ASG")
            end

            subgraph "Private DB Subnets"
                AuroraDB("Aurora PostgreSQL Cluster")
            end

            subgraph "Management Subnet"
                PuppetServer("Puppet Server")
            end
        end

        subgraph "AWS Services"
            IAM["IAM Roles & Profiles"]
            SecretsManager["Secrets Manager"]
            Route53["Route 53 Private Zone: internal.cashabl.local"]
        end
    end

    %% Connections
    User --> NginxALB
    NginxALB --> NginxASG
    NginxASG --> AppALB
    AppALB --> AppASG

    Admin -->|Connects via VPN Tunnel| ClientVPN
    ClientVPN -->|Provides access to| PuppetServer
    ClientVPN -->|Provides access to| AuroraDB

    AppASG -->|Reads Secret| SecretsManager
    AppASG -->|Connects using credentials| AuroraDB

    PuppetServer -->|Manages Config| NginxASG
    PuppetServer -->|Manages Config| AppASG

    AppALB -->|DNS Record| Route53
    NginxASG -->|Uses DNS of app_lb| Route53
    PuppetServer -->|DNS Record| Route53

    AppASG -->|Uses Instance Profile| IAM
    NginxASG -->|Uses Instance Profile| IAM
    PuppetServer -->|Uses Instance Profile| IAM

    %% Styling
    style NginxALB stroke:#D2691E,stroke-width:3px
    style AppALB stroke:#D2691E,stroke-width:3px
    style AuroraDB stroke:#4682B4,stroke-width:4px
    style PuppetServer stroke:#AF4C4C,stroke-width:3px
    style ClientVPN stroke:#6A5ACD,stroke-width:3px