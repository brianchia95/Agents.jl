# 2D CA using Agents.jl
module CA2D
using Agents

mutable struct Cell{T<:Integer, Y<:AbstractString} <: AbstractAgent
  id::T
  pos::Tuple{T, T}
  status::Y
end

"""
    build_model(;rules::Tuple, dims=(100,100), Moore=true)

Builds a 2D cellular automaton. `rules` is of type `Tuple{Integer,Integer,Integer}`. The numbers are DSR (Death, Survival, Reproduction). Cells die if the number of their living neighbors are <D, survive if the number of their living neighbors are <=S, come to life if their living neighbors are as many as R. `dims` is the x and y size a grid. `Moore` specifies whether cells should connect to their diagonal neighbors.
"""
function build_model(;rules::Tuple, dims=(100,100), Moore=true)
  space = Space(dims, moore=Moore, periodic=false)
  properties = Dict(:rules => rules)
  model = ABM(Cell, space; properties = properties, scheduler=by_id)
  nnodes = dims[1]*dims[2]
  for n in 1:nnodes
    add_agent!(Cell(n, vertex2coord(n, dims), "0"), (n,1), model)
  end
  return model
end

function ca_step!(model)
  new_status = Array{String}(undef, nagents(model))
  for (agid, ag) in model.agents
    neighbors_coords = node_neighbors(ag, model)
    nlive = 0
    for nc in neighbors_coords
      nag = model.agents[coord2vertex(nc, model)]
      if nag.status == "1"
        nlive += 1
      end
    end

    if ag.status == "1" &&
      (model.properties[:rules][4] < nlive ||
      model.properties[:rules][1] > nlive)
      new_status[agid] = "0"
    elseif ag.status == "0" && nlive == model.properties[:rules][3]
      new_status[agid] = "1"
    elseif ag.status == "1" && nlive == model.properties[:rules][2]
      new_status[agid] = "1"
    else
      new_status[agid] = "0"
    end
  end

  for k in keys(model.agents)
    model.agents[k].status = new_status[k]
  end
end

"""
    ca_run(model::ABM, runs::Integer)

Runs a 2D cellular automaton.
"""
function ca_run(model::ABM, runs::Integer, plot_CA2Dgif::T; nodesize=2) where T<: Function
  data = step!(model, dummystep, ca_step!, 0, [:pos, :status], step0=true)
  anim = plot_CA2Dgif(data, nodesize=nodesize)
  for r in 1:runs
    data = step!(model, dummystep, ca_step!, 1, [:pos, :status], step0=false)
    anim = plot_CA2Dgif(data, anim=anim, nodesize=nodesize)
  end
  return anim
end

end  # module
