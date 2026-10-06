# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::V3::WorkPackages::SemanticSearchAPI do
  shared_let(:project) { create(:project) }
  shared_let(:wp1) { create(:work_package, project:) }
  shared_let(:wp2) { create(:work_package, project:) }

  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:user) { create(:user, member_with_roles: { project => role }) }

  current_user { user }

  let(:body) { JSON.parse(last_response.body) }
  let(:response_work_packages) { body.dig("_embedded", "elements") }

  describe "GET /api/v3/work_packages/semantic_search?q=..." do
    before do
      allow(Search::SemanticResult).to receive(:ids).and_return([wp1.id, wp2.id])
      get "/api/v3/work_packages/semantic_search?q=hello"
    end

    it "returns a WorkPackageCollection" do
      expect(last_response).to have_http_status(:ok)
      expect(body["_type"]).to eq("WorkPackageCollection")
    end

    it "returns the work packages in the order provided by semantic search" do
      expect(response_work_packages.map { |wp| wp["id"] }).to eq([wp1.id, wp2.id])
    end

    context "when semantic search returns no results" do
      before do
        allow(Search::SemanticResult).to receive(:ids).and_return([])
        get "/api/v3/work_packages/semantic_search?q=hello"
      end

      it "returns an empty collection" do
        expect(last_response).to have_http_status(:ok)
        expect(response_work_packages).to be_empty
      end
    end

    context "without the q param" do
      before { get "/api/v3/work_packages/semantic_search" }

      it "returns HTTP 400" do
        expect(last_response).to have_http_status(:bad_request)
      end
    end

    context "not authorized" do
      let(:role) { create(:project_role, permissions: []) }

      it "returns HTTP 403" do
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "when semantic search returns IDs the user cannot see" do
      let(:unauthorized_wp) { create(:work_package) }

      before do
        allow(Search::SemanticResult).to receive(:ids).and_return([wp1.id, unauthorized_wp.id])
        get "/api/v3/work_packages/semantic_search?q=hello"
      end

      it "only returns visible work packages" do
        expect(response_work_packages.map { |wp| wp["id"] }).to contain_exactly(wp1.id)
      end
    end
  end
end
