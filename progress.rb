##
# Generate
# - [ ] **file-name.md**
# For pasting to GitHub issue.

Dir.chdir "#{Dir.home}/docs/guides/guides/edge"

File.open('../../progress.md', 'w') do |progress|
  Dir.glob("*.md").each do |guide|
    progress.write("- [ ] **#{guide}**\n")
  end
end
