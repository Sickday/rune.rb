module RuneRb::Game::Entity::Helpers::Equipment

  # Shorthand slot assignment
  # @param value [RuneRb::Game::Item::Stack] the item to assign
  # @param slot [Integer] the destination slot.
  def []=(slot, value)
    @equipment[slot] = value
  end

  alias equip []=

  # Shorthand slot retrieval
  # @param slot [Integer] the slot to retrieve
  def [](slot)
    @equipment[slot]
  end

  # Un-equips an slot.
  # @param slot [Integer] un-equips a slot.
  def unequip(slot)
    @equipment[slot] = -1
  end

  private

  # Creates default equipment data.
  # @param data [Hash] data that should be contained in this Equipment.
  def setup_equipment(data = nil)
    @equipment = data || { 0 => -1, # Hat
                           1 => -1, # Cape
                           2 => -1, # Amulet
                           3 => -1, # Weapon
                           4 => -1,
                           5 => -1,
                           6 => -1,
                           7 => -1,
                           8 => -1,
                           9 => -1,
                           10 => -1,
                           11 => -1,
                           12 => -1,
                           13 => -1 }
  end

  # Initialize Equipment for the Context. Attempts to load equipment from serialized dump or create a new empty Equipment model for the context.
  def load_equipment
    if !@profile.equipment.nil? && !Oj.load(@profile.equipment).empty?
      restore_equipment
    else
      setup_equipment
    end
    update(:equipment)
    log(RuneRb::COL.green("Loaded Equipment for #{RuneRb::COL.yellow(@profile.name)}")) if RuneRb::GLOBAL[:RRB_DEBUG]
  end

  # Dumps the equipment of a context entity
  def dump_equipment
    @profile.update(equipment: Oj.dump(@equipment.to_hash, mode: :compat, use_as_json: true))
  end

  # Restores the equipment of the context
  def restore_equipment
    data = Oj.load(@profile[:equipment])
    parsed = {}.tap do |hash|
      data.each do |slot, stack|
        hash[slot.to_i] = -1
        next if stack == -1 || stack.nil?

        hash[slot.to_i] = RuneRb::Game::Item::Stack.restore(id: stack['id'].to_i, amount: stack['amount'].to_i)
      end
    end
    setup_equipment(parsed)
  end
end