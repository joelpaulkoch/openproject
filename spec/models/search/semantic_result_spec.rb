# frozen_string_literal: true

require "spec_helper"

RSpec.describe Search::SemanticResult do
  describe ".ids" do
    let(:user) { create(:user) }

    it "returns the hardcoded dummy IDs" do
      expect(described_class.ids("some query", user)).to eq([1, 2, 3])
    end
  end
end
