require File.dirname(__FILE__) + "/github-emojis"

##
# task 'whatsoever'.to_sym do ; end
# This is necessary because rake will try to run every given args
# as a task, if you did not define it will raise an error.
##

##
# rake new README.md
desc "Add a new file to GitHub."
task :new do
  file_name = ARGV.last
  git_action(file_name, message: "Add #{file_name}", action: 'add')
  task file_name.to_sym do ; end
end

##
# rake mods
desc "Add all modified files and push to GitHub"
task :mods do
  git_action(nil, message: modified_msg, action: 'add -u')
end

##
# rake all
desc "Add all files and push to GitHub (including untracked)"
task :all do
  git_action(nil, message: modified_msg, action: 'add -A')
end

##
# rake update README.md
desc "Update a existing file to GitHub."
task :update do
  file_name = ARGV.last
  git_action(file_name)
  task file_name.to_sym do ; end
end

##
# rake msg "Update Guides." README.md
desc "Write a custom commit message then push to GitHub."
task :msg do
  message = ARGV[-2]
  file_name = ARGV.last
  git_action(file_name, message: message)
  task message.to_sym do ; end
  task file_name.to_sym do ; end
end

def git_action(file, **opts)
  message = if opts[:message].nil?
              if file == '.' || file.length <= 5
                "Update whole repo"
              else
                "Update #{file}"
              end
            else
              opts[:message]
            end

  message = if str_larger_than(modified_files_str, 50)
              "#{GITHUB_EMOJIS.sample} #{message} @ #{what_time_is_it}"
            else
              "#{message} @ #{what_time_is_it} #{GITHUB_EMOJIS.sample}"
            end

  if opts[:action].nil?
    system "git add #{file}"
  else
    system "git #{opts[:action]} #{file}"
  end

  system "git commit -m \"#{message}\""
  system "git push origin master"

  puts "\nDeploy to GitHub complete :)"
end

def what_time_is_it
  Time.now.utc
end

def str_larger_than(str, size)
  str.length > size
end

def modified_files_str
  `git ls-files -m`
end

##
# this will automatically create a list of modified file names
# if the string's length > 80, switch to a simplified message.
def modified_msg
  if str_larger_than(modified_files_str, 80)
    "Update Many Guides"
  else
    "Update ".concat(modified_files_str.chomp.gsub("\n", ", "))
  end
end
