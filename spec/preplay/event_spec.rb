require 'spec_helper'

describe PrePlay::Event do

  let(:now) { Time.now.to_s }
  before do
    allow(Time).to receive(:now).and_return(now)

    PrePlay::Event.configure do |c|
      c.field_whitelist = { 'user_follow' => %w{id username} }.freeze
    end
  end

  subject { PrePlay::Event(_event_type, _data, _context) }

  let(:_event_type) do
    'user_follow'
  end
  let(:_data) do
    {
      'id' => 'johndoe',
      'username' => 'john_doe',
      'forbidden' => 'content'
    }
  end
  let(:_context) do
    {
      'some' => 'context'
    }
  end

  let(:hash) do
    {:"d.type"=>"user_follow", :"d.id"=>"johndoe", :"d.username"=>"john_doe", :"c.some"=>"context", :"m.dyno"=>nil, :"m.created_at"=>now, :'preplay_event'=>true}
  end

  describe "#to_scrolls" do
    it { expect(subject).to eq(hash) }
  end

  describe "Event" do
    subject { PrePlay::Event.from_hash hash }

    its(:data) { should include({ 'id' => 'johndoe', 'username' => 'john_doe' }) }
    its(:context) { should include(_context) }
  end

  describe ".from_hash" do
    subject { PrePlay::Event.from_hash hash }

    it { expect(subject).to eq(described_class.new({'type'=> 'user_follow', 'id'=>'johndoe', 'username'=> 'john_doe'}, {'some'=> 'context'}, {'dyno'=> nil, 'created_at'=> now})) }
  end

  describe ".parse" do
    subject { PrePlay::Event.parse load_fixture('guess_updated_event.txt') }

    it { expect(subject).to eq PrePlay::Event.new({"type"=>"guess_updated", "choice"=>"5/3", "id"=>"stanko:final_score:fake_gid_2014_03_27_tbamlb_balmlb_1_90446"}, {"user_id"=>"stanko", "game_id"=>"fake_gid_2014_03_27_tbamlb_balmlb_1_90446", "guess_opportunity_id"=> "final_score:fake_gid_2014_03_27_tbamlb_balmlb_1_90446"}, {"dyno"=>"nil", "created_at"=>"01 April 2014 04:03 PM"}) }
  end
end
