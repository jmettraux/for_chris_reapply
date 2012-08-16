
require 'pp'

require 'rufus-json/automatic'
require 'ruote'
require 'ruote-redis'


#
# ruote conf

ruote = Ruote::Dashboard.new(
  Ruote::Worker.new(
    Ruote::Redis::Storage.new('db' => 14, 'thread_safe' => true)))

#ruote.noisy = ENV['NOISY'] == 'true'
ruote.noisy = true

ruote.storage.purge!

#
# actual case

# ---8<---
# define
#   subprocess tasklet
#
# define tasklet
#   cursor
#     subprocess work  <--- here
#
# define work
#   cursor tag: work2
# --->8---

pdef = Ruote.define do
  tasklet
  define 'tasklet' do
    cursor do
      work
    end
  end
  define 'work' do
    cursor :tag => 'work2' do
      stall
    end
  end
end

wfid = ruote.launch(pdef)

sleep 0.7

puts
pp ruote.ps(wfid).expressions.map { |e|
  [ e.name, e.fei.expid, e.fei.subid, e.state ].join(' ')
}

t = ruote.ps(wfid).expressions.find { |e| e.fei.expid == '0_0_0_0' }

puts
puts "re-applying: " + [ t.name, t.fei.expid, t.fei.subid, t.state ].join(' ')

ruote.re_apply(t)

sleep 0.7

puts
pp ruote.ps(wfid).expressions.map { |e|
  [ e.name, e.fei.expid, e.fei.subid, e.state ].join(' ')
}

puts

