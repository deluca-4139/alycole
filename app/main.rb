require "app/objects.rb"
require "app/map.rb"

def tick args
  args.state.game_over ||= false
  if !args.state.game_over
    init args
    render args
    input args
  else
    render_game_over args
  end
end

# Init variables and constants
def init args
  args.state.START_X ||= 200
  args.state.START_Y ||= 610
  args.state.TILE_SIZE ||= 40
  args.state.MAX_STATUS_AMOUNT ||= 28

  args.state.MAP_HEIGHT ||= args.state.map.length - 1
  args.state.MAP_WIDTH ||= args.state.map[0].length - 1
  args.state.player.START_AD ||= 3
  args.state.player.START_DEF ||= 0

  args.state.TILE_PATH ||= "sprites/tile3.png"

  args.state.player.max_health ||= 10
  args.state.player.current_health ||= 10
  args.state.player.ad ||= 3
  args.state.player.def ||= 0
  args.state.player.inventory ||= []
  args.state.player.inventory_size ||= 5
  args.state.player.direction ||= 0 # 0 for left, 1 for right
  args.state.inventory_drop ||= false

  args.state.enemies_killed ||= 0
  args.state.floor ||= 0
  args.state.damage_dealt ||= 0
  args.state.damage_received ||= 0
  args.state.potions_drank ||= 0

=begin
  args.state.map ||= [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
                      [1, 1, 1, Item.new(3, 1, 1, false, 5), 1, 1, 1, 1, 1, 1],
                      [1, 1, 1, 1, 1, 1, 1, 1, 1, Item.new(9, 2, 0, true, 15)],
                      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
                      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
                      [1, 1, 1, 1, 1, Enemy.new(5, 5), 1, 1, 1, 1],
                      [Item.new(0, 6, 2, false, 10), 1, 1, 1, 1, 1, 1, 1, 1, 1],
                      [1, 1, Item.new(2, 7, 0, true, 1), 1, 1, 1, 1, 1, 1, Enemy.new(9, 7)]]
=end

  args.state.player.x_pos ||= 0
  args.state.player.y_pos ||= 0
  args.state.player.x ||= args.state.START_X + 4
  args.state.player.y ||= args.state.START_Y + 4
  args.state.map ||= []
  args.state.enemies ||= []
  if args.tick_count == 0
    create_new_map args
  end

  args.state.status_text ||= []
end

# Various rendering sub-methods
def render args
  args.outputs.background_color = [128, 128, 128]

  # Render outlines
  args.outputs.borders << [5, 5, 180, 710] # Inventory
  args.outputs.borders << [190, 665, 700, 50] # Stats
  args.outputs.borders << [190, 5, 700, 650] # Map
  args.outputs.borders << [895, 5, 380, 710] # Status

  # Render map
  args.state.map.each_with_index do |row, index1|
    row.each_with_index do |column, index2|
      if column == 0
        args.outputs.sprites << {
          x: (args.state.START_X + (index2 * args.state.TILE_SIZE)),
          y: (args.state.START_Y - (index1 * args.state.TILE_SIZE)),
          w: args.state.TILE_SIZE,
          h: args.state.TILE_SIZE,
          path: "sprites/void1.png"
        }
      elsif column == 1
        args.outputs.sprites << {
          x: (args.state.START_X + (index2 * args.state.TILE_SIZE)),
          y: (args.state.START_Y - (index1 * args.state.TILE_SIZE)),
          w: args.state.TILE_SIZE,
          h: args.state.TILE_SIZE,
          path: args.state.TILE_PATH
        }
      elsif column == 2
        args.outputs.sprites << {
          x: (args.state.START_X + (index2 * args.state.TILE_SIZE)),
          y: (args.state.START_Y - (index1 * args.state.TILE_SIZE)),
          w: args.state.TILE_SIZE,
          h: args.state.TILE_SIZE,
          path: "sprites/stairs.png"
        }
      elsif column != 0
        args.outputs.sprites << {
          x: (args.state.START_X + (index2 * args.state.TILE_SIZE)),
          y: (args.state.START_Y - (index1 * args.state.TILE_SIZE)),
          w: args.state.TILE_SIZE,
          h: args.state.TILE_SIZE,
          path: args.state.TILE_PATH
        }
        column.render args
      end
    end
  end

  # Render player
  args.outputs.sprites << {
    x: args.state.player.x,
    y: args.state.player.y,
    w: 32,
    h: 32,
    path: "sprites/him.png",
    flip_horizontally: (args.state.player.direction == 0) ? false : true
  }

  # Render text
  args.outputs.labels << [200, 700, "Health: %d/%d" % [args.state.player.current_health, args.state.player.max_health]]
  args.outputs.labels << [400, 700, "Attack: %d" % [args.state.player.ad]]
  args.outputs.labels << [600, 700, "Armor: %d" % [args.state.player.def]]

  # Sanitize and render status texts
  while args.state.status_text.size > args.state.MAX_STATUS_AMOUNT
    args.state.status_text.pop
  end
  args.state.status_text.each_with_index do |text, index|
    args.outputs.labels << {
      x: 900,
      y: (705 - (index * 25)),
      text: text,
      size_enum: -2
      }
  end

  # Render inventory
  args.outputs.labels << [55, 700, "Inventory", 0, 0, 0]
  args.state.player.inventory_size.times do |i|
    args.outputs.labels << {
      x: 20,
      y: 650 - (i * 48),
      text: (i + 1).to_s + ".",
      size_enum: 1
    }
  end
  args.state.player.inventory.each do |item|
    item.render args
  end
end

# Handle keyboard input and update positioning accordingly
def input args
  move_taken = false

  # Handle inventory drop
  if args.state.inventory_drop
    [:one, :two, :three, :four, :five, :six, :seven, :eight, :nine].each_with_index do |num, index|
      if args.inputs.keyboard.truthy_keys.include? num
        if handle_inventory_drop args, index
          move_taken = true
        end
      end
    end

    if args.inputs.keyboard.key_down.q
      args.state.status_text.insert(0, "Inventory drop mode turned off.")
      args.state.inventory_drop = false
    end
  else
    # Movement controls
    if args.inputs.keyboard.key_down.up
      if args.state.player.y_pos > 0
        if args.state.map[(args.state.player.y_pos-1)][args.state.player.x_pos] == 1
          args.state.player.y_pos -= 1
          args.state.player.y += args.state.TILE_SIZE
          move_taken = true
        elsif args.state.map[(args.state.player.y_pos-1)][args.state.player.x_pos] == 2
          args.state.floor += 1
          args.audio[:new_floor] = {
            input: "sounds/godown.wav",
            gain: 1.0
          }
          create_new_map args
        elsif args.state.map[(args.state.player.y_pos-1)][args.state.player.x_pos] != 0
          if args.state.map[(args.state.player.y_pos-1)][args.state.player.x_pos].instance_of? Enemy
            handle_combat args.state.player.x_pos, args.state.player.y_pos-1, args
            move_taken = true
          elsif args.state.map[(args.state.player.y_pos-1)][args.state.player.x_pos].instance_of? Item
            item_picked_up = handle_item args.state.player.x_pos, args.state.player.y_pos-1, args
            if item_picked_up
              move_taken = true
            end
          end
        else
          puts "Can't move into non-tile space!"
        end
      else
        puts "Can't move off map!"
      end
    elsif args.inputs.keyboard.key_down.down
      if args.state.player.y_pos < args.state.MAP_HEIGHT
        if args.state.map[(args.state.player.y_pos+1)][args.state.player.x_pos] == 1
          args.state.player.y_pos += 1
          args.state.player.y -= args.state.TILE_SIZE
          move_taken = true
        elsif args.state.map[(args.state.player.y_pos+1)][args.state.player.x_pos] == 2
          args.state.floor += 1
          args.audio[:new_floor] = {
            input: "sounds/godown.wav",
            gain: 1.0
          }
          create_new_map args
        elsif args.state.map[(args.state.player.y_pos+1)][args.state.player.x_pos] != 0
          if args.state.map[(args.state.player.y_pos+1)][args.state.player.x_pos].instance_of? Enemy
            handle_combat args.state.player.x_pos, args.state.player.y_pos+1, args
            move_taken = true
          elsif args.state.map[(args.state.player.y_pos+1)][args.state.player.x_pos].instance_of? Item
            item_picked_up = handle_item args.state.player.x_pos, args.state.player.y_pos+1, args
            if item_picked_up
              move_taken = true
            end
          end
        else
          puts "Can't move into non-tile space!"
        end
      else
        puts "Can't move off map!"
      end
    elsif args.inputs.keyboard.key_down.right
      if args.state.player.x_pos < args.state.MAP_WIDTH
        if args.state.map[args.state.player.y_pos][(args.state.player.x_pos+1)] == 1
          args.state.player.x_pos += 1
          args.state.player.x += args.state.TILE_SIZE
          args.state.player.direction = 1
          move_taken = true
        elsif args.state.map[args.state.player.y_pos][(args.state.player.x_pos+1)] == 2
          args.state.floor += 1
          args.audio[:new_floor] = {
            input: "sounds/godown.wav",
            gain: 1.0
          }
          create_new_map args
        elsif args.state.map[args.state.player.y_pos][(args.state.player.x_pos+1)] != 0
          if args.state.map[args.state.player.y_pos][(args.state.player.x_pos+1)].instance_of? Enemy
            handle_combat args.state.player.x_pos+1, args.state.player.y_pos, args
            args.state.player.direction = 1
            move_taken = true
          elsif args.state.map[args.state.player.y_pos][(args.state.player.x_pos+1)].instance_of? Item
            item_picked_up = handle_item args.state.player.x_pos+1, args.state.player.y_pos, args
            args.state.player.direction = 1
            if item_picked_up
              move_taken = true
            end
          end
        else
          puts "Can't move into non-tile space!"
        end
      else
        puts "Can't move off map!"
      end
    elsif args.inputs.keyboard.key_down.left
      if args.state.player.x_pos > 0
        if args.state.map[args.state.player.y_pos][(args.state.player.x_pos-1)] == 1
          args.state.player.x_pos -= 1
          args.state.player.x -= args.state.TILE_SIZE
          args.state.player.direction = 0
          move_taken = true
        elsif args.state.map[args.state.player.y_pos][(args.state.player.x_pos-1)] == 2
          args.state.floor += 1
          args.audio[:new_floor] = {
            input: "sounds/godown.wav",
            gain: 1.0
          }
          create_new_map args
        elsif args.state.map[args.state.player.y_pos][(args.state.player.x_pos-1)] != 0
          if args.state.map[args.state.player.y_pos][(args.state.player.x_pos-1)].instance_of? Enemy
            handle_combat args.state.player.x_pos-1, args.state.player.y_pos, args
            args.state.player.direction = 0
            move_taken = true
          elsif args.state.map[args.state.player.y_pos][(args.state.player.x_pos-1)].instance_of? Item
            item_picked_up = handle_item args.state.player.x_pos-1, args.state.player.y_pos, args
            args.state.player.direction = 0
            if item_picked_up
              move_taken = true
            end
          end
        else
          puts "Can't move into non-tile space!"
        end
      else
        puts "Can't move off map!"
      end
    end

    # Inventory controls
    [:one, :two, :three, :four, :five, :six, :seven, :eight, :nine].each_with_index do |num, index|
      if args.inputs.keyboard.truthy_keys.include? num
        if handle_inventory args, index
          move_taken = true
        end
      end
    end

    # Toggle inventory drop mode
    if args.inputs.keyboard.key_down.q
      args.state.inventory_drop = true
      args.state.status_text.insert(0, "Inventory drop mode turned on.")
    end

    # Allow pass of turn
    if args.inputs.keyboard.key_down.space
      move_taken = true
      args.state.status_text.insert(0, "Passed.")
    end
  end

  # If we've properly done an action,
  # allow enemies to act as well
  if move_taken
    handle_enemies args
  end
end

# Called from input when colliding with enemy
def handle_combat x, y, args
  args.audio[:damage_deal] = {
    input: "sounds/hitenemy.wav",
    gain: 1.0
  }
  args.state.map[y][x].health -= args.state.player.ad
  args.state.damage_dealt += args.state.player.ad
  if args.state.map[y][x].health <= 0
    args.state.enemies.delete args.state.map[y][x]
    args.state.map[y][x] = 1
    args.state.status_text.insert(0, "Enemy killed!")
    args.audio[:enemy_death] = {
      input: "sounds/kill.wav",
      gain: 1.0
    }
    args.state.enemies_killed += 1
  else
    args.state.status_text.insert(0, "Dealt %d damage to enemy. (Remaining health: %d)" % [args.state.player.ad, args.state.map[y][x].health])
  end
end

# Called from input when colliding with item
def handle_item x, y, args
  if args.state.player.inventory.size == args.state.player.inventory_size
    args.state.status_text.insert(0, "Your inventory is full!")
  else
    item_type = args.state.map[y][x].type
    has_item_type = false
    item_index = 0
    args.state.player.inventory.each_with_index do |item, index|
      if item.type == item_type
        has_item_type = true
        item_index = index
      end
    end

    if has_item_type && item_type != 0
      args.state.status_text.insert(0, "You're already holding a%s item. (%d->%d)" % [((item_type == 1) ? "n attack" : " defense"), args.state.player.inventory[item_index].attribute_val, args.state.map[y][x].attribute_val])
      return false
    else
      args.state.map[y][x].in_inventory = true
      args.state.map[y][x].inventory_pos = args.state.player.inventory.size
      args.state.player.inventory.append args.state.map[y][x]
      args.audio[:item_pickup] = {
        input: "sounds/pickup.wav",
        gain: 1.0
      }
      args.state.map[y][x] = 1
      args.state.player.x_pos = x
      args.state.player.y_pos = y
      args.state.player.x = 5 + args.state.START_X + (x * args.state.TILE_SIZE)
      args.state.player.y = 5 + args.state.START_Y - (y * args.state.TILE_SIZE)
      update_player args
      return true
    end
  end
end

# Called from input when number pressed
def handle_inventory args, index
  if (index + 1) <= args.state.player.inventory_size && (index + 1) <= args.state.player.inventory.size
    # If not consumable, don't use item
    if args.state.player.inventory[index].consumable == false
      args.state.status_text.insert(0, "That item is not usable!")
      false
    # Else check for type of item and handle accordingly
    else
      if args.state.player.inventory[index].type == 0
        if args.state.player.current_health == args.state.player.max_health
          args.state.status_text.insert(0, "You are already at full health!")
          false
        else
          if args.state.player.max_health - args.state.player.current_health >= args.state.player.inventory[index].attribute_val
            args.state.player.current_health += args.state.player.inventory[index].attribute_val
          else
            args.state.player.current_health = args.state.player.max_health
          end
          args.state.status_text.insert(0, "Restored %d health!" % [args.state.player.inventory[index].attribute_val])
          args.audio[:potion_drink] = {
            input: "sounds/drinkpotino.wav",
            gain: 1.0
          }
          args.state.potions_drank += 1
          args.state.player.inventory.delete_at index
          args.state.player.inventory.each do |item|
            if item.inventory_pos > 0 && item.inventory_pos > index
              item.inventory_pos -= 1
            end
          end
          true
        end
      end
    end
  end
end

# Called from input when state.inventory_drop
# is true and a number is pressed
def handle_inventory_drop args, index
  if (index + 1) < args.state.player.inventory_size && (index + 1) <= args.state.player.inventory.size
    if args.state.map[args.state.player.y_pos][args.state.player.x_pos] == 1
      args.state.player.inventory[index].in_inventory = false
      args.state.player.inventory[index].x_pos = args.state.player.x_pos
      args.state.player.inventory[index].y_pos = args.state.player.y_pos
      args.state.map[args.state.player.y_pos][args.state.player.x_pos] = args.state.player.inventory[index]
      args.state.player.inventory.delete_at index
      args.state.player.inventory.each do |item|
        if item.inventory_pos > 0 && item.inventory_pos > index
          item.inventory_pos -= 1
        end
      end
      args.state.status_text.insert(0, "Item dropped.")
      args.audio[:item_drop] = {
        input: "sounds/itemdrop.wav",
        gain: 1.0
      }
      args.state.inventory_drop = false
      return true
    else
      args.state.status_text.insert(0, "There is already an item at your feet.")
      return false
    end
  end
end

# Called from input after successful move
def handle_enemies args
  args.state.enemies.each do |enemy|
    enemy.act args
  end
end

# Update internal player stats; called when item is picked up or dropped
def update_player args
  ad_update = args.state.player.START_AD
  def_update = args.state.player.START_DEF
  args.state.player.inventory.each do |item|
    if item.type == 1
      ad_update += item.attribute_val
    elsif item.type == 2
      def_update += item.attribute_val
    end
  end
  args.state.player.ad = ad_update
  args.state.player.def = def_update
end

# Called when a new map is needed; i.e. from
# game start and upon loading new room
def create_new_map args
  args.state.map = []
  args.state.enemies = []
  args.state.player.x_pos = 0
  args.state.player.y_pos = 0
  args.state.player.x = args.state.START_X + 4
  args.state.player.y = args.state.START_Y + 4

  map_genned = false
  while !map_genned
    args.state.map = gen_map args
    total_cells = 0
    args.state.map.each do |row|
      row.each do |tile|
        if tile != 0
          total_cells += 1
        end
      end
    end
    if total_cells > 15 # Force map to have minimum number of accessible tiles
      map_genned = true
    end
  end

  args.state.map.each do |row|
    row.each do |tile|
      if tile.instance_of? Enemy
        args.state.enemies << tile
      end
    end
  end
end

# Called from tick when game over (player has 0 health)
def render_game_over args
  args.outputs.labels << {
    x: 500,
    y: 500,
    text: "GAME OVER",
    size_enum: 20
  }

  args.outputs.labels << {
    x: 525,
    y: 400,
    text: "Floors traversed: %d" % [args.state.floor],
    size_enum: 1
  }
  args.outputs.labels << {
    x: 540,
    y: 365,
    text: "Enemies killed: %d" % [args.state.enemies_killed],
    size_enum: 1
  }
  args.outputs.labels << {
    x: 540,
    y: 330,
    text: "Damage dealt: %d" % [args.state.damage_dealt],
    size_enum: 1
  }
  args.outputs.labels << {
    x: 520,
    y: 295,
    text: "Damage received: %d" % [args.state.damage_received],
    size_enum: 1
  }
  args.outputs.labels << {
    x: 540,
    y: 260,
    text: "Potions drank: %d" % [args.state.potions_drank],
    size_enum: 1
  }

  button = {
    x: 557,
    y: 100,
    w: 150,
    h: 50
  }
  args.outputs.borders << button
  args.outputs.labels << {
    x: 595,
    y: 137,
    text: "Retry?",
    size_enum: 2
  }

  if args.inputs.mouse.intersect_rect? button
    args.outputs.solids << {
      x: 557,
      y: 100,
      w: 150,
      h: 50,
      a: 40
    }
    if args.inputs.mouse.down
      args.audio[:retry] = {
        input: "sounds/retry.wav",
        gain: 1.0
      }

      args.state.player.max_health = 10
      args.state.player.current_health = 10
      args.state.player.ad = 3
      args.state.player.def = 0
      args.state.player.inventory = []
      args.state.player.inventory_size = 5
      args.state.status_text = []
      args.state.game_over = false

      args.state.enemies_killed = 0
      args.state.floor = 0
      args.state.damage_dealt = 0
      args.state.damage_received = 0
      args.state.potions_drank = 0

      create_new_map args
    end
  end
end
