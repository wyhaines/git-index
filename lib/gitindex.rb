require 'sqlite3'
require 'find'
require 'gitindex/config'

module GitIndex

  class << self
    def run
      @config = Config::parse_command_line

      case @config[ :command ]
      when :delete
        delete_records(database)
      when :insert
        index_git_repositories(database, git_directories)
      when :list
        list_records(database)
      when :query
        query_records(database)
      end
    end

    def database
      db = SQLite3::Database.new @config[ :database ]

      begin
        db.execute("select 1 from repositories") do |row|
          break
        end
      rescue SQLite3::Exception => e
        db.execute <<~SQL
          create table repositories (
            hash varchar(160),
            path varchar(250)
          );
        SQL
      end

      db
    end

    def git_directories
      if @config[:recurse]
        untrimmed_directories = []
        ARGV.each do | base_path |
          Find.find( base_path ) do |path|
            Find.prune if path.include? '.git'
            Find.prune unless File.directory?(path)
            Find.prune if system("git -C #{File.join(path,'..')} rev-parse --is-inside-work-tree > /dev/null 2>&1")
            untrimmed_directories << File.expand_path( path )
          end
        end
      else
        untrimmed_directories = ARGV
      end

      untrimmed_directories.select do |dir|
        system("git -C #{dir} rev-parse --is-inside-work-tree > /dev/null 2>&1")
      end
    end

    def index_git_repositories( db, dirs )
      dirs.each do |dir|
        codes = `git -C #{dir} rev-list --parents HEAD | tail -2`.split("\n")
        hash = codes.length > 1 ? codes.first : codes.last

        if hash =~ /^([\w\d]+)\s+([\w\d]+)$/
          hash = "#{$2}#{$1}"
        end
        db.execute("DELETE FROM repositories WHERE hash = ?", [hash]) unless @config[:dryrun]
        db.execute("INSERT INTO repositories (hash, path) VALUES (?, ?)", [hash, File.expand_path(dir)]) unless @config[:dryrun]
        puts "#{hash} -> #{File.expand_path(dir)}" if @config[:verbose]
      end
    end

    def delete_records(db)
      ARGV.each do |path_or_hash|
        if FileTest.exist?(File.expand_path(path_or_hash))
          path_or_hash = File.expand_path(path_or_hash)
          puts "deleting path #{path_or_hash}" if @config[:verbose]
          db.execute("DELETE FROM repositories WHERE path = ?", [path_or_hash]) unless @config[:dryrun]
        else
          puts "deleting hashes like #{path_or_hash}" if @config[:verbose]
          db.execute("DELETE FROM repositories where hash like ?", ["#{path_or_hash}%"]) unless @config[:dryrun]
        end
      end
    end

    def list_records(db)
      puts "hash,path"
      db.execute("SELECT hash, path FROM repositories") do |row|
        puts row.join(',')
      end
    end

    def query_records(db)
      ARGV.each do |hash|
        db.execute("SELECT hash, path from repositories WHERE hash like ?", ["#{hash}%"]) do |row|
          puts "#{hash}: #{row[1]}"
        end
      end
    end

  end
end
