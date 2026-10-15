namespace DeskBox.Tests;

public sealed class Windows10InstallerCompatibilityContractTests
{
    [Theory]
    [InlineData("installer/DeskBox.iss")]
    [InlineData("installer/DeskBox.arm64.iss")]
    public void DirectInstaller_MatchesPackagedWindows10Minimum(string scriptPath)
    {
        string installer = File.ReadAllText(TestPaths.FromRepository(scriptPath));
        string manifest = File.ReadAllText(TestPaths.FromRepository(
            "src/DeskBox/Package.appxmanifest"));

        Assert.Contains("MinVersion=10.0.17763", installer, StringComparison.Ordinal);
        Assert.Contains("MinVersion=\"10.0.17763.0\"", manifest, StringComparison.Ordinal);
    }

    [Fact]
    public void Windows10Floor_IsDeclaredConsistentlyAcrossProjectsAndProbes()
    {
        // 17763 (Windows 10 1809 / LTSC 2019) is this branch's floor. Upstream ships
        // 19041, the base build of the 19041-19045 servicing family; this branch
        // deliberately moves to an earlier, separate family so LTSC 2019 hosts can
        // install. Every declared floor must still move together.
        foreach (string projectPath in new[]
                 {
                     "src/DeskBox/DeskBox.csproj",
                     "src/DeskBox.Updater/DeskBox.Updater.csproj",
                     "tests/DeskBox.Tests/DeskBox.Tests.csproj",
                     "tests/DeskBox.NotificationActivationProbe/DeskBox.NotificationActivationProbe.csproj"
                 })
        {
            string project = File.ReadAllText(TestPaths.FromRepository(projectPath));
            Assert.Contains(
                "<SupportedOSPlatformVersion>10.0.17763.0</SupportedOSPlatformVersion>",
                project,
                StringComparison.Ordinal);
        }

        string mainProject = File.ReadAllText(TestPaths.FromRepository("src/DeskBox/DeskBox.csproj"));
        Assert.Contains(
            "<TargetPlatformMinVersion>10.0.17763.0</TargetPlatformMinVersion>",
            mainProject,
            StringComparison.Ordinal);

        string startupProbe = File.ReadAllText(TestPaths.FromRepository(
            "scripts/Test-StoreStartupTaskLifecycle.ps1"));
        Assert.Contains("MinVersion=\"10.0.17763.0\"", startupProbe, StringComparison.Ordinal);

        string notificationProbe = File.ReadAllText(TestPaths.FromRepository(
            "tests/DeskBox.NotificationActivationProbe/Run-MSIX.ps1"));
        Assert.Contains("MinVersion=\"10.0.17763.0\"", notificationProbe, StringComparison.Ordinal);
    }
}
