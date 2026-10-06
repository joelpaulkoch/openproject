# frozen_string_literal: true

module API
  module V3
    module WorkPackages
      class SemanticSearchAPI < ::API::OpenProjectAPI
        include Utilities::PathHelper

        helpers do
          def collection_representer(work_packages, per_page:)
            ::API::V3::WorkPackages::WorkPackageCollectionRepresenter.new(
              work_packages,
              self_link: api_v3_paths.work_packages,
              project: nil,
              query_params: {},
              page: 1,
              per_page:,
              groups: nil,
              total_sums: nil,
              embed_schemas: true,
              current_user:
            )
          end
        end

        resources :semantic_search do
          params do
            requires :q, type: String
          end

          get do
            authorize_in_any_work_package(:view_work_packages)

            ids = Search::SemanticResult.ids(params[:q], current_user)

            return collection_representer(WorkPackage.none, per_page: 0) if ids.empty?

            work_packages = WorkPackage
              .visible(current_user)
              .where(id: ids)
              .order(Arel.sql("array_position(ARRAY[#{ids.join(',')}]::int[], work_packages.id)"))

            collection_representer(work_packages, per_page: ids.length)
          end
        end
      end
    end
  end
end
