function getconfig()
  config = Dict()
  open("config.json", "r") do f
    config = JSON.parse(readall(f))
  end
  return config
end
