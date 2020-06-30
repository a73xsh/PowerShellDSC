@{
    AllNodes =
    @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        },

        @{
            NodeName = "localhost"
            Role     = "Hyper-V"
            Site     = "TEST-LOC"
        }
    );

}