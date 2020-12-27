require_relative 'app/rune'

controller = RuneRb::System::Controller.new

home_world = controller.deploy(:world, { world_id: rand(0xff) })
home_point = controller.deploy(:endpoint, { world: home_world })
controller.run