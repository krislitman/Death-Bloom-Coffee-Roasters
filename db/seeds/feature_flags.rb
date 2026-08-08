# Flags are added if missing; their enabled/disabled state is never overwritten
# so toggling in the admin UI persists across re-seeds.
%i[
  subscriptions
  admin_tools
  announcement_bar
  maintenance_mode
  newsletter
  google_auth
  inventory
].each do |flag|
  Flipper.add(flag) unless Flipper.exist?(flag)
end

puts "Feature flags seeded: #{Flipper.features.map(&:key).join(', ')}"
