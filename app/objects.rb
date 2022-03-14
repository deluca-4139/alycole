class Enemy
  attr_accessor :x_pos
  attr_accessor :y_pos
  attr_accessor :health
  attr_accessor :ad

  def initialize x, y, h, attack
    @x_pos = x
    @y_pos = y
    @health = h
    @ad = attack
  end

  def act args
    move_pq = []
    # Player will only be right next to this enemy if
    # sum of differences of coordinates is equal to 1
    if ((@x_pos - args.state.player.x_pos).abs + (@y_pos - args.state.player.y_pos).abs) == 1
      total_attack = (@ad - (@ad * (args.state.player.def / 100))).floor
      args.state.player.current_health -= total_attack
      args.state.damage_received += total_attack
      if args.state.player.current_health <= 0
        args.audio[:death] = {
          input: "sounds/ded.wav",
          gain: 1.0
        }
        args.state.game_over = true
      end
      args.state.status_text.insert(0, "Received %d damage." % [total_attack]) # TODO: edit to add source of damage?
      args.audio[:damage_receive] = {
        input: "sounds/oof.wav",
        gain: 1.0
      }
    # Move towards player if visible
    # Take longest path first
    elsif can_see_player args
      x_dif = @x_pos - args.state.player.x_pos
      y_dif = @y_pos - args.state.player.y_pos

      if x_dif.abs > y_dif.abs
        move_pq << ((x_dif > 0) ? ["x", -1] : ["x", 1])
        move_pq << ((y_dif > 0) ? ["y", -1] : ["y", 1])
        move_pq << ((x_dif > 0) ? ["x", 1] : ["x", -1])
        move_pq << ((y_dif > 0) ? ["y", 1] : ["y", -1])
      elsif y_dif.abs > x_dif.abs
        move_pq << ((y_dif > 0) ? ["y", -1] : ["y", 1])
        move_pq << ((x_dif > 0) ? ["x", -1] : ["x", 1])
        move_pq << ((y_dif > 0) ? ["y", 1] : ["y", -1])
        move_pq << ((x_dif > 0) ? ["x", 1] : ["x", -1])
      elsif y_dif.abs == x_dif.abs
        if rand(100) > 50
          move_pq << ((x_dif > 0) ? ["x", -1] : ["x", 1])
          move_pq << ((y_dif > 0) ? ["y", -1] : ["y", 1])
          move_pq << ((x_dif > 0) ? ["x", 1] : ["x", -1])
          move_pq << ((y_dif > 0) ? ["y", 1] : ["y", -1])
        else
          move_pq << ((y_dif > 0) ? ["y", -1] : ["y", 1])
          move_pq << ((x_dif > 0) ? ["x", -1] : ["x", 1])
          move_pq << ((y_dif > 0) ? ["y", 1] : ["y", -1])
          move_pq << ((x_dif > 0) ? ["x", 1] : ["x", -1])
        end
      end
    else
      if @x_pos < args.state.map[0].size
        move_pq << ["x", 1]
      end
      if @y_pos < args.state.map.size
        move_pq << ["y", 1]
      end
      if @x_pos > 0
        move_pq << ["x", -1]
      end
      if @y_pos > 0
        move_pq << ["y", -1]
      end
      move_pq = move_pq.shuffle
    end
    move_taken = false
    move_pq.each do |move|
      if move_taken
        break
      else
        if move[0] == "x" && ((@x_pos + move[1]) > 0 && (@x_pos + move[1]) < args.state.map[0].size)
          if args.state.map[@y_pos][(@x_pos + move[1])] == 1
            old_x_pos = @x_pos
            @x_pos += move[1]
            args.state.map[@y_pos][@x_pos] = args.state.map[@y_pos][old_x_pos]
            move_taken = true
            args.state.map[@y_pos][old_x_pos] = 1
          end
        elsif move[0] == "y" && ((@y_pos + move[1]) > 0 && (@y_pos + move[1]) < args.state.map.size)
          if args.state.map[(@y_pos + move[1])][@x_pos] == 1
            old_y_pos = @y_pos
            @y_pos += move[1]
            args.state.map[@y_pos][@x_pos] = args.state.map[old_y_pos][@x_pos]
            move_taken = true
            args.state.map[old_y_pos][@x_pos] = 1
          end
        end
      end
    end
  end

  def can_see_player args
    if (@x_pos == args.state.player.x_pos) && ((@y_pos - args.state.player.y_pos).abs <= 4)
      true
    elsif (@y_pos == args.state.player.y_pos) && ((@x_pos - args.state.player.x_pos).abs <= 4)
      true
    elsif ((@x_pos - args.state.player.x_pos).abs + (@y_pos - args.state.player.y_pos).abs) <= 4
      true
    else
      false
    end
  end

  def render args
    args.outputs.sprites << {
      x: 4 + (args.state.START_X + (@x_pos * args.state.TILE_SIZE)),
      y: 4 + (args.state.START_Y - (@y_pos * args.state.TILE_SIZE)),
      w: 32,
      h: 32,
      path: "sprites/slime.png"
    }
  end
end

class Item
  attr_accessor :type
  attr_accessor :in_inventory
  attr_accessor :consumable
  attr_accessor :attribute_val
  attr_accessor :inventory_pos
  attr_accessor :x_pos
  attr_accessor :y_pos

  # Type key:
  # 0: health item
  # 1: attack damage (ad) item
  # 2: armor item
  def initialize x, y, t, c, v
    @x_pos = x
    @y_pos = y
    @type = t
    @in_inventory = false
    @consumable = c
    @attribute_val = v
    @inventory_pos = -1 # Only used for rendering, not storage
  end

  def render args
    p = ""
    t = ""
    if @type == 0
      p = "sprites/potino.png"
      t = "HP: +%d" % [@attribute_val]
    elsif @type == 1
      p = "sprites/sword1.png"
      t = "AD: +%d" % [@attribute_val]
    elsif @type == 2
      p = "sprites/shield1.png"
      t = "DF: +%d" % [@attribute_val]
    end

    if @in_inventory
      args.outputs.sprites << {
        x: 60,
        y: 630 - (@inventory_pos * 48),
        w: 32,
        h: 32,
        path: p,
        angle: 0
      }
      args.outputs.labels << {
        x: 115,
        y: 650 - (@inventory_pos * 48),
        text: t,
        size_enum: -2
      }
    else
      args.outputs.sprites << {
        x: 4 + (args.state.START_X + (@x_pos * args.state.TILE_SIZE)),
        y: 4 + (args.state.START_Y - (@y_pos * args.state.TILE_SIZE)),
        w: 32,
        h: 32,
        path: p,
        angle: 0
      }
    end
  end
end
