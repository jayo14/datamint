/**
 * DataMint Unified Web Frontend API Client
 * Connects directly to the FastAPI Backend (/api/v1) via Next.js proxy rewrite or custom URL.
 */

export interface UserProfile {
  id: string;
  email?: string;
  display_name?: string;
  avatar_url?: string;
  reputation_score: number;
  is_active: boolean;
  capabilities: Array<{
    capability_type: 'CONTRIBUTOR' | 'CREATOR' | 'REVIEWER' | 'ADMIN';
    is_enabled: boolean;
  }>;
  wallets: Array<{
    address: string;
    chain_id: number;
    is_primary: boolean;
  }>;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  user: UserProfile;
}

export interface NonceResponse {
  nonce: string;
  issued_at: string;
  expires_at: string;
}

export interface Campaign {
  id: string;
  title: string;
  description: string;
  instructions: string;
  data_type: 'TEXT' | 'VOICE' | 'IMAGE';
  category?: string;
  reward_per_submission: string | number;
  target_submissions: number;
  current_submissions: number;
  status: 'DRAFT' | 'PENDING_FUNDING' | 'ACTIVE' | 'PAUSED' | 'COMPLETED' | 'CANCELLED';
  creator_id: string;
  created_at: string;
  deadline?: string;
}

export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

export interface SubmissionAsset {
  id: string;
  asset_type: 'AUDIO' | 'IMAGE';
  storage_key: string;
  byte_size: number;
  mime_type: string;
  is_uploaded: boolean;
}

export interface ValidationFinding {
  id: string;
  severity: 'INFO' | 'WARNING' | 'REJECT';
  rule_code: string;
  message: string;
}

export interface ValidationRun {
  id: string;
  status: string;
  score: number;
  findings: ValidationFinding[];
  created_at: string;
}

export interface SubmissionDetails {
  id: string;
  campaign_id: string;
  contributor_id: string;
  status: string;
  content_payload?: Record<string, unknown>;
  submitted_at?: string;
  created_at: string;
  assets: SubmissionAsset[];
  validation_runs: ValidationRun[];
  payout_authorization?: {
    id: string;
    amount: string;
    status: string;
    voucher_hash: string;
    signature: string;
  };
}

export interface PayoutVoucher {
  submission_id: string;
  contributor_address: string;
  onchain_campaign_id?: string;
  amount: string;
  amount_raw_units?: string;
  nonce?: string;
  deadline?: number;
  voucher_hash: string;
  signature: string;
  status: string;
  claim_tx_hash?: string;
}

class ApiClient {
  private get baseUrl(): string {
    return '/api/v1';
  }

  private getAuthToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('datamint_access_token');
  }

  public setAuthToken(token: string): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('datamint_access_token', token);
    }
  }

  public clearAuthToken(): void {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('datamint_access_token');
      localStorage.removeItem('datamint_refresh_token');
    }
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${this.baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;
    const token = this.getAuthToken();

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...((options.headers as Record<string, string>) || {}),
    };

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      let errorMessage = `HTTP Error ${response.status}`;
      try {
        const errorJson = await response.json();
        errorMessage = errorJson.detail || errorJson.message || JSON.stringify(errorJson);
      } catch {
        errorMessage = await response.text();
      }
      throw new Error(errorMessage);
    }

    if (response.status === 204) {
      return {} as T;
    }

    return response.json() as Promise<T>;
  }

  // ---------------------------------------------------------------------------
  // Auth & Identity
  // ---------------------------------------------------------------------------
  async getSiweNonce(address: string, chainId: number = 42220): Promise<NonceResponse> {
    return this.request<NonceResponse>('/auth/nonce', {
      method: 'POST',
      body: JSON.stringify({ address, chain_id: chainId, action: 'login' }),
    });
  }

  async verifySiwe(message: string, signature: string): Promise<AuthResponse> {
    const res = await this.request<AuthResponse>('/auth/verify', {
      method: 'POST',
      body: JSON.stringify({ message, signature }),
    });
    if (res.access_token) {
      this.setAuthToken(res.access_token);
    }
    return res;
  }

  async login(email: string, password: string): Promise<AuthResponse> {
    const res = await this.request<AuthResponse>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    if (res.access_token) {
      this.setAuthToken(res.access_token);
    }
    return res;
  }

  async register(email: string, password: string, role: string = 'BOTH'): Promise<AuthResponse> {
    const res = await this.request<AuthResponse>('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email, password, role }),
    });
    if (res.access_token) {
      this.setAuthToken(res.access_token);
    }
    return res;
  }

  async getMe(): Promise<UserProfile> {
    return this.request<UserProfile>('/users/me');
  }

  // ---------------------------------------------------------------------------
  // Marketplace & Campaigns
  // ---------------------------------------------------------------------------
  async listMarketplace(params?: {
    search?: string;
    dataType?: string;
    category?: string;
    page?: number;
    pageSize?: number;
  }): Promise<Paginated<Campaign>> {
    const query = new URLSearchParams();
    if (params?.search) query.append('search', params.search);
    if (params?.dataType) query.append('data_type', params.dataType);
    if (params?.category) query.append('category', params.category);
    if (params?.page) query.append('page', params.page.toString());
    if (params?.pageSize) query.append('page_size', params.pageSize.toString());

    return this.request<Paginated<Campaign>>(`/marketplace/tasks?${query.toString()}`);
  }

  async getCampaign(id: string): Promise<Campaign> {
    return this.request<Campaign>(`/campaigns/${id}`);
  }

  async createCampaign(payload: {
    title: string;
    description: string;
    instructions: string;
    data_type: 'TEXT' | 'VOICE' | 'IMAGE';
    reward_per_submission: number;
    target_submissions: number;
    category?: string;
  }): Promise<Campaign> {
    return this.request<Campaign>('/campaigns', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  async submitCampaignForFunding(id: string): Promise<{
    campaign_id: string;
    title: string;
    total_budget: string;
    reward_per_submission: string;
    onchain_params: {
      campaign_id_bytes32: string;
      deposit_amount_cusd: string;
      deposit_amount_raw_units: string;
    };
  }> {
    return this.request(`/campaigns/${id}/submit-funding`, {
      method: 'POST',
    });
  }

  async getMyCampaigns(page: number = 1, pageSize: number = 20): Promise<Paginated<Campaign>> {
    return this.request<Paginated<Campaign>>(`/campaigns/my-campaigns?page=${page}&page_size=${pageSize}`);
  }

  // ---------------------------------------------------------------------------
  // Submissions Lifecycle
  // ---------------------------------------------------------------------------
  async createSubmissionDraft(campaignId: string, contentPayload?: Record<string, unknown>): Promise<SubmissionDetails> {
    return this.request<SubmissionDetails>('/submissions/drafts', {
      method: 'POST',
      body: JSON.stringify({
        campaign_id: campaignId,
        content_payload: contentPayload || {},
      }),
    });
  }

  async requestMediaUploadUrl(submissionId: string, payload: {
    filename: string;
    mime_type: string;
    byte_size: number;
    asset_type: 'AUDIO' | 'IMAGE';
    checksum_sha256?: string;
  }): Promise<{
    submission_id: string;
    upload_url: string;
    storage_key: string;
    expires_at: string;
  }> {
    return this.request(`/submissions/drafts/${submissionId}/upload-url`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  async confirmMediaUpload(submissionId: string, assetId: string): Promise<SubmissionAsset> {
    return this.request(`/submissions/drafts/${submissionId}/confirm-upload`, {
      method: 'POST',
      body: JSON.stringify({ asset_id: assetId }),
    });
  }

  async submitForValidation(submissionId: string): Promise<SubmissionDetails> {
    return this.request<SubmissionDetails>(`/submissions/drafts/${submissionId}/submit`, {
      method: 'POST',
    });
  }

  async getSubmissionDetails(submissionId: string): Promise<SubmissionDetails> {
    return this.request<SubmissionDetails>(`/submissions/${submissionId}`);
  }

  async getCampaignSubmissions(campaignId: string, page: number = 1, pageSize: number = 20): Promise<Paginated<SubmissionDetails>> {
    return this.request<Paginated<SubmissionDetails>>(`/submissions/campaigns/${campaignId}?page=${page}&page_size=${pageSize}`);
  }

  async getMySubmissions(page: number = 1, pageSize: number = 20): Promise<Paginated<SubmissionDetails>> {
    return this.request<Paginated<SubmissionDetails>>(`/submissions/my-submissions?page=${page}&page_size=${pageSize}`);
  }

  // ---------------------------------------------------------------------------
  // Payouts & Vouchers
  // ---------------------------------------------------------------------------
  async getPayoutVoucher(submissionId: string): Promise<PayoutVoucher> {
    return this.request<PayoutVoucher>(`/payouts/submissions/${submissionId}/voucher`);
  }

  async recordOnChainClaim(submissionId: string, claimTxHash: string): Promise<{
    submission_id: string;
    claim_tx_hash: string;
    status: string;
  }> {
    return this.request(`/payouts/submissions/${submissionId}/claim`, {
      method: 'POST',
      body: JSON.stringify({ claim_tx_hash: claimTxHash }),
    });
  }

  // ---------------------------------------------------------------------------
  // Health & Diagnostics
  // ---------------------------------------------------------------------------
  async checkHealth(): Promise<{ status: string; service: string }> {
    return this.request('/health/healthz');
  }

  async checkReadiness(): Promise<{ status: string; database?: string; redis?: string }> {
    return this.request('/health/readyz');
  }
}

export const api = new ApiClient();
