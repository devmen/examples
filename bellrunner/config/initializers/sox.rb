SOX_CONFIG = { }
SOX_CONFIG[:command]         = "sox"
SOX_CONFIG[:soxi_command]    = "soxi"
SOX_CONFIG[:mp3slt]          = "mp3splt"
SOX_CONFIG[:finaly_mix_name] = "mix-track.mp3"
SOX_CONFIG[:insert_sound]    = File.join(Rails.root, "app", "assets", "audio", "mr_jump.mp3")
SOX_CONFIG[:fade_seconds]    = '3'
SOX_CONFIG[:split_length]     = '30'
