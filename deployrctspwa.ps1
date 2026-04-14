# 1. VERSION CHECK REMINDER
Write-Host "!!! VERSION CHECK !!!" -ForegroundColor Yellow
Write-Host "Have you updated the version string in:"
Write-Host "  1. lib/version_check_service.dart"
Write-Host "  2. web/version.json"
$confirm = Read-Host "Type 'y' to proceed or any other key to cancel"

if ($confirm -ne "y") {
    Write-Host "Deployment cancelled. Update your version strings first!" -ForegroundColor Red
    exit
}

# 2. Ask for the commit message
$custom_message = Read-Host "Enter your commit message"

# Check if message is empty
if ([string]::IsNullOrWhiteSpace($custom_message)) {
    $custom_message = "Update and deploy: $(Get-Date)"
}

# 3. Update the GitHub Source Repository
Write-Host "--- Updating Source Code ---" -ForegroundColor Cyan
git add .
git commit -m "$custom_message"
git push origin main

# 4. Build the Flutter Web Project
Write-Host "--- Building Flutter Web (Release) ---" -ForegroundColor Cyan
flutter clean
flutter pub get
flutter build web --release --base-href "/rcts-27-pwa-app/"

# 5. Deploy to GitHub Pages
Write-Host "--- Deploying to gh-pages ---" -ForegroundColor Cyan
Set-Location build/web

git init
git remote add origin https://github.com/leelemon0/rcts-27-pwa-app.git
git checkout -b gh-pages

git add .
git commit -m "Deploy: $custom_message"
git push origin gh-pages --force

# Navigate back to project root
Set-Location ../..
Write-Host "--- Deployment Complete! ---" -ForegroundColor Green