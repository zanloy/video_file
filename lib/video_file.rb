module VideoFile
  class VideoFile
    attr_reader :filename, :absolute_path, :basename, :ext, :path, :series_id
    attr_accessor :title, :description, :director, :imdb_id, :rating, :lang
    def initialize(path = nil)
      if path then
        self.path=(path)
      end
    end
    def path=(path)
      @absolute_path = File.absolute_path(path)
      @filename = File.basename(path)
      @ext = File.extname(path)
      @basename = File.basename(@filename, @ext)
    end
  end
  class TVShow < VideoFile
    attr_accessor :episode_name, :first_aired, :tvdb_id, :tvdb_series_id
    attr_reader :season, :season_str, :episode, :episode_str
    def initialize(path = nil)
      @regexes = [
        /(?<show>.*?)( - |\.)[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2}).*/,
        /(?<show>.*?)[\._ -](?<season>\d)(?<episode>\d{2}).*/,
        /(?<show>.*?)[\._ -](?<season>\d{1,2})x(?<episode>\d{1,2}).*/,
      ]
      super(path)
    end
    def path=(path)
      super(path)
      @regexes.each { |regex|
        if result = regex.match(@basename) then
          @title = result[:show].gsub(/\./, ' ')
          self.season = result[:season]
          self.episode = result[:episode]
          break
        end
      }
    end
    def season=(season)
      if season.class != Fixnum then
        season = season.to_i
      end
      @season_str = "%02d" % season
      @season = season
    end
    def episode=(episode)
      if episode.class != Fixnum then
        episode = episode.to_i
      end
      @episode_str = "%02d" % episode
      @episode = episode
    end
    def query_tvdb(apikey)
      require 'thetvdb'
      client = TheTVDB::Client.new(apikey)
      client.search(@title)
      result = client.get_episode_info(@season, @episode)
      @title = result[:show]
      @tvdb_id = result[:tvdb_id]
      @series_id = result[:series_id]
      @episode_name = result[:name]
      @first_aired = Date.parse(result[:first_aired])
      @imdb_id = result[:imdb_id]
    end
    def new_filename(pattern: "::title:: - S::season_str::E::episode_str:: - ::episode_name::::ext::", directory: nil)
      pattern.gsub!( /::(.*?)::/ ) { '#{@'+$1+'}' }
      filename = eval( '"' + pattern + '"' )
      filename.gsub!(/[\/\\?\*:\|"<>]/, '')
      filename.gsub!(/  /, ' ')
      filename.gsub!(/\.$/, '')
      if directory then
        directory.gsub!( /::(.*?)::/ ) { '#{@'+$1+'}' }
        directory = eval( '"' + directory + '"' )
        File.join(directory, filename)
      else
        filename
      end
    end
  end
end
