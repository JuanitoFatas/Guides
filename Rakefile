require File.dirname(__FILE__) + "/github-emojis"

##
# rake new README.md
desc "Add a new post to GitHub."
task :new do
  file_name = ARGV.last
  git_action(file_name, 'Add')
  task file_name.to_sym do ; end
end

##
# rake mods
desc "Add modified files to GitHub"
task :mods do
  git_action(nil, modfied_msg, action: 'git add -u')
end

##
# rake update README.md
desc "Update a existing post to GitHub."
task :update do
  file_name = ARGV.last
  git_action(file_name, 'Update')
  task file_name.to_sym do ; end
end

##
# rake msg "Update Guides." README.md
desc "Write a custom commit message then deploy to GitHub."
task :msg do
  message = ARGV[-2]
  file_name = ARGV.last
  git_action(file_name, nil, message: message)
  task message.to_sym do ; end
  task file_name.to_sym do ; end
end

def git_action(file, action, **opts) (custom=false)
  if opts[:action].nil?
    system "git add #{file}"
  else
    system opts[:action]
  end

  if opts[:message].nil?
    message = "#{action} #{file}"
  else
    message = "#{opts[:message]}"
  end

  message.concat " @ #{what_time_is_it} #{GITHUB_EMOJIS.sample}"

  system "git commit -m \"#{message}\""
  system "git push origin master"

  puts "\nDeploy to GitHub complete :)"
end

def what_time_is_it
  Time.now.utc
end

def modfied_msg
  modified_files_string = `git ls-files -m`
  if modified_files_string.length > 28
    "Update Many Guides"
  else
    "Update ".concat(modified_files_string.chomp.gsub("\n", ", "))
  end
end
