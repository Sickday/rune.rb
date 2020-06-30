horse_phrases = ['Come on Dobbin, we can win the race!',
                 'Hi-ho Silver, and away!',
                 'Neaahhhyyy! Giddy-up horsey!'].freeze

(2520..2526).step(2) do |id|
  on_item_click(id) do |player, _slot|
    player.force_chat horse_phrases[rand(horse_phrases.size)]
    player.play_animation RuneRb::Model::Animation.new(918 + (id - 2520) / 2)
  end
end
