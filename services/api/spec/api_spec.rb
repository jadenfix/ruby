require 'spec_helper'

RSpec.describe 'GemHub API' do
  describe 'Health Check' do
    it 'returns healthy status' do
      get '/health'
      expect(last_response.status).to eq(200)
      expect(json_response['status']).to eq('healthy')
    end
  end

  describe 'Authentication' do
    it 'requires authentication for protected endpoints' do
      get '/gems'
      expect(last_response.status).to eq(401)
    end

    it 'allows access with valid token' do
      get '/gems', nil, auth_headers
      expect(last_response.status).to eq(200)
    end
  end

  describe 'Gems CRUD' do
    let(:gem_data) do
      {
        name: 'test-gem',
        version: '1.0.0',
        description: 'A test gem',
        homepage: 'https://example.com',
        license: 'MIT'
      }
    end

    describe 'GET /gems' do
      it 'returns empty list when no gems exist' do
        get '/gems', nil, auth_headers
        expect(last_response.status).to eq(200)
        expect(json_response['gems']).to eq([])
      end

      it 'returns all gems' do
        gem = create(:gem_record)
        get '/gems', nil, auth_headers
        expect(last_response.status).to eq(200)
        expect(json_response['gems'].length).to eq(1)
        expect(json_response['gems'].first['name']).to eq(gem.name)
      end
    end

    describe 'POST /gems' do
      it 'creates a new gem' do
        post '/gems', gem_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(201)
        expect(json_response['gem']['name']).to eq('test-gem')
        expect(json_response['gem']['version']).to eq('1.0.0')
      end

      it 'validates required fields' do
        post '/gems', { name: 'test' }.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(422)
      end

      it 'validates gem name format' do
        invalid_data = gem_data.merge(name: 'invalid-name!')
        post '/gems', invalid_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(422)
      end

      it 'validates version format' do
        invalid_data = gem_data.merge(version: 'invalid')
        post '/gems', invalid_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(422)
      end

      it 'prevents duplicate gem names' do
        create(:gem_record, name: 'test-gem')
        post '/gems', gem_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(422)
      end
    end

    describe 'GET /gems/:id' do
      it 'returns a specific gem' do
        gem = create(:gem_record)
        get "/gems/#{gem.id}", nil, auth_headers
        expect(last_response.status).to eq(200)
        expect(json_response['gem']['name']).to eq(gem.name)
      end

      it 'returns 404 for non-existent gem' do
        get '/gems/999', nil, auth_headers
        expect(last_response.status).to eq(404)
      end
    end

    describe 'PUT /gems/:id' do
      it 'updates a gem' do
        gem = create(:gem_record)
        update_data = { description: 'Updated description' }
        put "/gems/#{gem.id}", update_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(200)
        expect(json_response['gem']['description']).to eq('Updated description')
      end

      it 'returns 404 for non-existent gem' do
        put '/gems/999', {}.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(404)
      end
    end

    describe 'DELETE /gems/:id' do
      it 'deletes a gem' do
        gem = create(:gem_record)
        delete "/gems/#{gem.id}", nil, auth_headers
        expect(last_response.status).to eq(200)
        expect(GemRecord[gem.id]).to be_nil
      end

      it 'returns 404 for non-existent gem' do
        delete '/gems/999', nil, auth_headers
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'Ratings' do
    let(:gem) { create(:gem_record) }
    let(:rating_data) do
      {
        score: 5,
        comment: 'Excellent gem!',
        user_id: 'test-user'
      }
    end

    describe 'GET /gems/:id/ratings' do
      it 'returns ratings for a gem' do
        rating = create(:rating, gem_record: gem)
        get "/gems/#{gem.id}/ratings", nil, auth_headers
        expect(last_response.status).to eq(200)
        expect(json_response['ratings'].length).to eq(1)
        expect(json_response['ratings'].first['score']).to eq(rating.score)
      end

      it 'returns empty list when no ratings exist' do
        get "/gems/#{gem.id}/ratings", nil, auth_headers
        expect(last_response.status).to eq(200)
        expect(json_response['ratings']).to eq([])
      end

      it 'returns 404 for non-existent gem' do
        get '/gems/999/ratings', nil, auth_headers
        expect(last_response.status).to eq(404)
      end
    end

    describe 'POST /gems/:id/ratings' do
      it 'creates a rating' do
        post "/gems/#{gem.id}/ratings", rating_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(201)
        expect(json_response['rating']['score']).to eq(5)
        expect(json_response['rating']['comment']).to eq('Excellent gem!')
      end

      it 'validates rating score' do
        invalid_data = rating_data.merge(score: 6)
        post "/gems/#{gem.id}/ratings", invalid_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(422)
      end

      it 'updates gem average rating' do
        post "/gems/#{gem.id}/ratings", rating_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        gem.reload
        expect(gem.rating).to eq(5.0)
      end
    end
  end

  describe 'Badges' do
    let(:gem) { create(:gem_record) }
    let(:badge_data) do
      {
        gem_id: gem.id,
        type: 'quality',
        name: 'Well-Tested',
        description: 'Comprehensive test coverage'
      }
    end

    describe 'GET /badges' do
      it 'returns all badges' do
        badge = create(:badge, gem_record: gem)
        get '/badges', nil, auth_headers
        expect(last_response.status).to eq(200)
        expect(json_response['badges'].length).to eq(1)
        expect(json_response['badges'].first['name']).to eq(badge.name)
      end
    end

    describe 'POST /badges' do
      it 'creates a badge' do
        post '/badges', badge_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(201)
        expect(json_response['badge']['name']).to eq('Well-Tested')
        expect(json_response['badge']['type']).to eq('quality')
      end

      it 'validates badge type' do
        invalid_data = badge_data.merge(type: 'invalid')
        post '/badges', invalid_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(422)
      end
    end
  end

  describe 'CVE Scanner' do
    describe 'POST /scan' do
      it 'returns scan status' do
        scan_data = { gem_name: 'test-gem' }
        post '/scan', scan_data.to_json, auth_headers.merge('CONTENT_TYPE' => 'application/json')
        expect(last_response.status).to eq(200)
        expect(json_response['gem_name']).to eq('test-gem')
        expect(json_response['scan_status']).to eq('pending')
      end
    end
  end
end 