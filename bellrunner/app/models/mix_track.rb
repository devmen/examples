require 'tmpdir'
require 'fileutils'

class MixTrack < ActiveRecord::Base

  attr_accessible :attachment
  has_attached_file :attachment

  class << self

    def log(msg)
      Rails.logger.info(msg)
    end

    # Mixing Tracks
    #
    def mixing_tracks(tracks)
      tracks_path =  tracks.map{ |j| j.attachment.path }
      Dir.chdir tmp_dir

      log("merge tracks")
      Cocaine::CommandLine.new(::SOX_CONFIG[:command], "--combine sequence #{ tracks_path.map{ |j| shell_quote(j) }.join(' ') } #{tmp_dir}/merge_files.mp3 ").run

      log("split tracks by 30 seconds")
      Cocaine::CommandLine.new(::SOX_CONFIG[:mp3slt], "-Q -t 0.30  -o sound-@N -d split merge_files.mp3 ").run

      fade_segments(sort_files(Dir["#{tmp_dir}/split/*"]))

      # New Mix Track
      #
      log("create super song")
      splitting_files = sort_files(Dir["#{tmp_dir}/split/*"])

      Cocaine::CommandLine.new(::SOX_CONFIG[:command],
                               "--combine sequence #{splitting_files.map{ |j| shell_quote(j) }.join(" #{ SOX_CONFIG[:insert_sound]  } ")} #{::SOX_CONFIG[:finaly_mix_name]}").run

      create({ :attachment => File.open(File.join(tmp_dir, ::SOX_CONFIG[:finaly_mix_name])) } )

    rescue => ex
      Rails.logger.error ex.inspect
      Rails.logger.error caller[0]
      nil

    ensure

      # clear tmp dir
      Dir.chdir Rails.root
      FileUtils.rm_rf tmp_dir
      @tmp_dir = nil
    end

    # Sort file by digit in filename
    #
    def sort_files(list_files = [])
      list_files.map{|j| [j, (j.match(/(\d+)/) && $1).to_i ] }.sort{|v1,v2| v1.last <=> v2.last }.map(&:first)
    end

    private

    def fade_segments(track_segments)
      segments = track_segments.dup

      # Fade first 30 seconds
      #
      log("fade first track")
      if first_segment = segments.shift
        Cocaine::CommandLine.new(::SOX_CONFIG[:command], "-V1 :file_from  :file_to fade 0 30 :fade_seconds ",
                                 file_from:    File.expand_path('.',first_segment),
                                 file_to:      File.expand_path('.',first_segment.gsub("sound", 'fade_sound') ),
                                 fade_seconds: ::SOX_CONFIG[:fade_seconds]
                                 ).run

        FileUtils.rm_f(File.expand_path('.',first_segment))
      end

      # Fade last 30 seconds
      #
      log("fade last track")
      if last_segment  = segments.pop
        Cocaine::CommandLine.new(::SOX_CONFIG[:command], " -V1 :file_from :file_to fade :fade_seconds",
                                 file_from:    File.expand_path('.',last_segment),
                                 file_to:      File.expand_path('.',last_segment.gsub("sound", 'fade_sound') ),
                                 fade_seconds: ::SOX_CONFIG[:fade_seconds]
                                 ).run
        FileUtils.rm_f(File.expand_path('.',last_segment))
      end

      # Both fade
      #
      log("fade other tracks")
      (segments||[]).each do |s_file|
        Cocaine::CommandLine.new(::SOX_CONFIG[:command], " -V1 :file_from :file_to fade :fade_seconds 30 :fade_seconds",
                                 file_from:    File.expand_path('.',s_file),
                                 file_to:      File.expand_path('.',s_file.gsub("sound", 'fade_sound') ),
                                 fade_seconds: ::SOX_CONFIG[:fade_seconds]
                                 ).run
        FileUtils.rm_f(File.expand_path('.',s_file))
      end

    end
    # Create tmp dir
    #
    def tmp_dir
      @tmp_dir ||= File.join(Rails.root, 'tmp', [ Time.now.to_i, rand(1000000) ].join).tap{ |j| FileUtils.mkdir_p(j) }
      @tmp_dir
    end

    # Quite string for shell command
    #
    def shell_quote(str = "")
      @tmp_command_line ||= Cocaine::CommandLine.new("")
      @tmp_command_line.send :shell_quote, str
    end

  end

end
