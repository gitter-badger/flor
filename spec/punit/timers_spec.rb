
#
# specifying flor
#
# Mon Jul  4 16:24:35 JST 2016
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf[:unit] = 'pu_timers'
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.stop
    @unit.storage.clear
    @unit.shutdown
  end

  describe 'timers' do

    it 'sets timers' do

      flon = %{
        sequence
          timers
            reminder 'first reminder' after: '5d'
            timeout after: '9d'
          stall _
      }

      exid = @unit.launch(flon, payload: { 'x' => 'y' })

      sleep 0.350

      ts = @unit.timers.all

      expect(ts.collect(&:nid)).to eq(%w[ 0 0 ])
      expect(ts.collect(&:type)).to eq(%w[ in in ])
      expect(ts.collect(&:schedule)).to eq(%w[ 5d 9d ])

      tds = ts.collect(&:data)
      tms = tds.collect { |td| td['message'] }

      expect(tms.collect { |m| m['point'] }).to eq(%w[ execute execute ])
      expect(tms.collect { |m| m['nid'] }).to eq(%w[ 0_0_0 0_0_1 ])
      #expect(tms.collect { |m| m['from'] }).to eq(%w[ 0 0 ])
      expect(tms.collect { |m| m['from'] }).to eq([ nil, nil ])
    end

    it 'fails if there is no parent node' do

      flon = %{
        timers
          reminder 'first reminder' after: '5d'
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq('no parent node for "timers" at line 2')
    end

    it 'sets timers with after: or in:' do

      flon = %{
        sequence
          timers
            reminder in: '5d'
            reminder at: '7d'
            timeout after: '9d'
          stall _
      }

      exid = @unit.launch(flon)

      sleep 0.350

      ts = @unit.timers.all

      expect(ts.collect(&:nid)).to eq(%w[ 0 0 0 ])
      expect(ts.collect(&:type)).to eq(%w[ in in in ])
      expect(ts.collect(&:schedule)).to eq(%w[ 5d 7d 9d ])

      tds = ts.collect(&:data)
      tms = tds.collect { |td| td['message'] }
      expect(tms.collect { |m| m['point'] }).to eq(%w[ execute ] * 3)
      expect(tms.collect { |m| m['nid'] }).to eq(%w[ 0_0_0 0_0_1 0_0_2 ])
    end

    it 'triggers for its parent node' do

      flon = %{
        sequence
          timers; trace 'reminder0' after: '1s' | trace 'reminder1' after: '2s'
          stall _
      }

      #r = @unit.launch(flon, wait: '0_0_0 ceased')
      r = @unit.launch(flon, wait: [ 'ceased', 'ceased' ])

      expect(r['point']).to eq('ceased')
      expect(r['nid']).to eq(nil)
      expect(r['from']).to eq('0_0_1')

      ed = @unit.executions[exid: r['exid']].data

      expect(ed['nodes'].keys).to eq(%w[ 0 0_1 ])

      traces = @unit.traces.all

      expect(
        traces.collect { |t| "#{t.nid}:#{t.text}" }
      ).to eq(%w[
        0_0_0:reminder0
        0_0_1:reminder1
      ])
    end

    it 'triggers and understands "timeout"' do

      flon = %{
        sequence; timers; timeout after: '1s'
          stall _
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('terminated')
      expect(r['cause']).to eq('cancel')
      expect(r['payload']).to eq({})
    end
  end
end
