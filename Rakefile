require File.dirname(__FILE__) + "/github-emojis"

##
# this repository's path
DOCGUIDES_REPO_PATH  = "#{Dir.home}/docs/guides"

##
# where you clone rails/rails
RAILS_EDGE_REPO_PATH = "#{Dir.home}/dev/rails-edge/guides/source"

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
  git_action(nil, message: 'Update the whole repository', action: 'add -A')
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
# rake bupdate xxxxx-zh_CN.md
# will also update xxxxx-zh_TW counterpart.
desc "Bilingual Update a existing file to GitHub."
task :bupdate do
  file_name = ARGV.last
  if file_name.scan(/zh_CN/).empty?
    git_action(file_name)
    git_action(file_name.gsub('zh_TW', 'zh_CN'))
  else
    git_action(file_name)
    git_action(file_name.gsub('zh_CN', 'zh_TW'))
  end
  task file_name.to_sym do ; end
end

##
# rake msg "Update Guides." README.md
desc "Write a custom commit message then push to GitHub."
task :msg do
  message   = ARGV[-2]
  file_name = ARGV.last
  git_action(file_name, message: message)
  task message.to_sym   do ; end
  task file_name.to_sym do ; end
end

desc "Update edge guides from Rails repo."
task :update_guide do
  system "cd #{RAILS_EDGE_REPO_PATH} && git pull"
    puts "Pulling Latest Changes from rails/rails..."
  system "cp #{RAILS_EDGE_REPO_PATH}/*.md #{DOCGUIDES_REPO_PATH}/guides/edge/"
    puts "All Guides Updated Successfully."
end

desc "Sync EN guides with upstream"
task :sync_guide do
  system 'rake msg "Sync edge guides with upstream." guides/edge/'
end

def git_action(file, **opts)
  message = if opts[:message].nil?
              "Update #{file}"
            else
              opts[:message]
            end

  message = if str_larger_than(modified_files_str, 38)
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
  Time.now.to_s.gsub('+0800', '(Taipei Time)')
end

def str_larger_than(str, size)
  str.length > size
end

def modified_files_str
  `git ls-files -m`.chomp.gsub("\n", ", ")
end

##
# this will automatically create a list of modified file names
# if the string's length > 80, switch to a simplified message.
def modified_msg
  if str_larger_than(modified_files_str, 80)
    "Update Many Guides"
  else
    "Update ".concat(modified_files_str)
  end
end
