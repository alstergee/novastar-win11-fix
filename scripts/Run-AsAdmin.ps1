# Run-AsAdmin.ps1 - Helper to run commands as Administrator
param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [string]$Arguments = ""
)

if ($Arguments) {
    Start-Process $Command -ArgumentList $Arguments -Verb RunAs
} else {
    Start-Process $Command -Verb RunAs
}
