module RuneRb::Equipment
  SIDEBARS ||= {}.freeze
  SLOTS ||= [].freeze
  EXCEPTIONS ||= [].freeze

  LOG ||= Logging.logger['data']

  def self.load
    begin
      # Load sidebars
      SIDEBARS.clear
      XmlSimple.xml_in('data/equipment_sidebars.xml', 'KeyToSymbol' => true)[:sidebar].each do |sidebar|
        SIDEBARS[sidebar['regex'].to_regexp] = {type: sidebar['type'].to_sym, id: sidebar['id'].to_i}
      end

      # Load slots
      SLOTS.clear
      XmlSimple.xml_in('data/equipment_slots.xml', 'KeyToSymbol' => true).each do |slot|
        SLOTS << {slot: slot['id'].to_i, check: slot['check'].to_i, names: slot[:name]}
      end

      # Load exceptions
      EXCEPTIONS.clear
      XmlSimple.xml_in('data/equipment_exceptions.xml', 'KeyToSymbol' => true)[:exception].each do |exception|
        EXCEPTIONS << {id: exception['id'].to_i, slot: exception['slot'].to_i}
      end
    rescue StandardError => e
      LOG.error('Failed to load equipment data!')
      LOG.error(e)
    end
  end

  def self.slot(name)
    SLOTS.find { |e| e[:names].find { |s| name.downcase.include?(s) } }[:slot] || 3
  end

  def self.is(item, type)
    SLOTS.find { |e| e[:check] == type }[:names].any? do |s|
      item.definition.name.downcase.include?(s)
    end
  end

  def self.get_exception(id)
    item = EXCEPTIONS.find { |e| e[:id] == id }
    item && item[:slot]
  end

  def self.equip(player, item, slot, name, id)
    return unless item&.id == id

    equip_slot = get_exception(item.id)
    equip_slot = slot(name) if equip_slot.nil?
    old_equip = nil
    stackable = false

    if player.equipment.is_slot_used(equip_slot) && !stackable
      old_equip = player.equipment.items[equip_slot]
      player.equipment.set(equip_slot, nil)
    end

    player.inventory.set(slot, nil)
    player.inventory.add(old_equip) unless old_equip.nil?
    stackable ? player.equipment.add(item) : player.equipment.set(equip_slot, item)
  end

  class AppearanceContainerListener < RuneRb::Item::ContainerListener
    attr :player

    def initialize(player)
      @player = player
    end

    def slot_changed(_container, _slot)
      @player.flags.flag(:appearance)
    end

    def slots_changed(_container, _slots)
      @player.flags.flag(:appearance)
    end

    def items_changed(_container)
      @player.flags.flag(:appearance)
    end
  end

  class SidebarContainerListener < RuneRb::Item::ContainerListener
    MATERIALS ||= %w[Iron Steel Scythe Black Mithril Adamant Rune Granite Dragon Crystal Bronze].freeze

    attr :player

    def initialize(player)
      @player = player
    end

    def slot_changed(_container, slot)
      send_weapon if slot == 3
    end

    def slots_changed(_container, slots)
      slot = slots.find { |e| e == 3 }
      send_weapon unless slot.nil?
    end

    def items_changed(_container)
      send_weapon
    end

    def send_weapon
      weapon = player.equipment.items[3]

      if weapon
        name = weapon.definition.name
        send_sidebar(name, weapon.id, find_sidebar_interface(name))
      else
        # No weapon wielded
        @player.io.send_sidebar_interface(0, 5855)
        @player.io.send_string(5857, 'Unarmed')
      end
    end

    private

    def find_sidebar_interface(name)
      SIDEBARS.each do |matcher, data|
        formatted_name = data[:type] == :generic ? filter_name(name) : name
        return data[:id] if formatted_name =~ matcher
      end

      2423
    end

    def send_sidebar(name, id, interface_id)
      @player.io.send_sidebar_interface(0, interface_id)
      @player.io.send_interface_model(interface_id + 1, 200, id)
      @player.io.send_string(interface_id + 3, name)
    end

    def filter_name(name)
      name = name.dup
      MATERIALS.each { |m| name.gsub!(Regexp.new(m), '') }
      name.strip
    end
  end
end

# Wield item
on_item_wield(3214) do |player, item, slot, name, id|
  case id
  when 4079 # Loop yo-yo
    player.play_animation(RuneRb::Model::Animation.new(1458))
  when 6865 # Walk Marrionette(blue)
    player.play_animation(RuneRb::Model::Animation.new(3004))
    player.play_graphic(RuneRb::Model::Graphic.new(512, 2))
  when 6866 # Walk Marrionette(green)
    player.play_animation(RuneRb::Model::Animation.new(3004))
    player.play_graphic(RuneRb::Model::Graphic.new(516, 2))
  when 6867 # Walk Marrionette(red)
    player.play_animation(RuneRb::Model::Animation.new(3004))
    player.play_graphic(RuneRb::Model::Graphic.new(508, 2))
  else
    RuneRb::Equipment.equip(player, item, slot, name, id)
  end
end

# Unwield item
on_item_option(1688) do |player, id, slot|
  RuneRb::Item::Container.transfer(player.equipment, player.inventory, slot, id)
end

