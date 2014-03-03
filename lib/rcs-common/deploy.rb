module RCS
  class Deploy
    attr_reader :me, :target

    def initialize(params)
      @target = Target.new(params)
      @me = Me.new
      @target.me = @me
    end

    module Task
      def self.import
        deploy_task = 'rcs-common/tasks/deploy.rake'

        if File.exists?("../#{deploy_task}")
          load("../#{deploy_task}")
        else
          laod(deploy_task)
        end
      end
    end

    class Me
      attr_reader :path

      def initialize
        @path ||= File.expand_path(Dir.pwd)

        raise "Missing rakefile" unless File.exists?("#{@path}/Rakefile")
        raise "Not in a git repo" unless Dir.exists?("#{@path}/.git")
      end

      def run(cmd, opts = {})
        puts "executing: #{cmd}"
        opts[:trap] ? `#{cmd}` : Kernel.system(cmd)
      end

      def pending_changes?
        run("cd \"#{path}\" && git status", trap: true) !~ /nothing to commit, working directory clean/
      end

      def ask(question)
        print("#{question} (y/n) ")
        answer = STDIN.getc
        STDIN.readline
        answer.strip.downcase == 'y'
      end
    end

    class Target
      attr_reader :user, :address
      attr_accessor :me

      def initialize(params)
        @user = params[:user]
        @address = params[:address]
      end

      def add_slash(path)
        path.end_with?('/') ? "#{path}" : "#{path}/"
      end

      def mirror!(local_folder, remote_folder, opts = {})
        src = add_slash(local_folder)
        dst = add_slash(remote_folder)

        me.run("rsync --delete -vazc \"#{src}\" #{user}@#{address}:\"#{dst}\"", opts)
      end

      def mirror(local_folder, remote_folder, opts = {})
        opts[:trap] = true
        result = mirror!(local_folder, remote_folder, opts)
        changes = result.split("\n")[1..-3].reject { |x| x.empty? }
        changed = changes.size > 0 && changes != ["./"]

        if opts[:changes]
          changed ? result : nil
        else
          changed
        end
      end

      def restart_service(name)
        run("net stop \"#{name}\"; net start \"#{name}\"")
      end

      def run(command, opts = {})
        me.run("ssh #{user}@#{address} \""+ command.gsub('"', '\"') +"\"", opts)
      end
    end
  end
end