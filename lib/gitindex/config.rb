
require 'optparse'

module GitIndex
  module Config
    class << self

      def parse_command_line
        config = {
          :database => "#{ENV['HOME']}/.git-index.db",
          :recurse => false,
          :verbose => false
        }

        options = OptionParser.new do |opts|
          opts.banner = <<~EBANNER
            Usage: git-index [OPTIONS] PATH1 PATH2 PATHn

            This tool takes one or more paths and checks them for the presence of a git repository. If one exists, it writes a record into the database of the first and second commit hashes of the repository and the path to the repository.
          EBANNER
          opts.separator ''
          opts.on( '-d', '--database', String, 'The database file to write to. Defaults to $HOME/.git-index.db' ) do |path|
            config[:database] = path
          end
          opts.on( '-r', '--recurse', 'Recursively search through the provided directories for git repositories.' ) do
            config[:recurse] = true
          end
          opts.on( '-x', '--delete', 'The command line arguments are assumed to be hashes or paths to delete from the databse.' ) do
            config[:command] = :delete
          end
          opts.on( '-l', '--list', 'List the known repositories' ) do
            config[:command] = :list
          end
          opts.on( '-v', '--verbose', 'Provide extra output about actions') do
            config[:verbose] = true
          end
          opts.on( '-n', '--dry-run', "Find git repositories, but do not actually store them in the database. This option doesn't do much without also specifying --verbose." ) do
            config[:dryrun] = true
          end
        end

        leftover_argv = []
        begin
          options.parse!(ARGV)
        rescue OptionParser::InvalidOption => e
          e.recover ARGV
          leftover_argv << ARGV.shift
          leftover_argv << ARGV.shift if ARGV.any? && ( ARGV.first[0..0] != '-' )
          retry
        end

        ARGV.replace( leftover_argv ) if leftover_argv.any?

        config[:command] ||= :insert
        config
      end
    end
  end
end
