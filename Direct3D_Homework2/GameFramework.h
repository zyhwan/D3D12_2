#pragma once

#define FRAME_BUFFER_WIDTH		800
#define FRAME_BUFFER_HEIGHT		600

#include "Timer.h"
#include "Player.h"
#include "Scene.h"

class MainCScene;

class CGameFramework
{
public:
	CGameFramework();
	~CGameFramework();
	//direct3D �ʱ� ���� �� ����
	bool OnCreate(HINSTANCE hInstance, HWND hMainWnd);
	void OnDestroy();
	//���� ü�� �� ����̽� ��ġ ���ť�� ����Ʈ ����
	void CreateSwapChain();
	void CreateDirect3DDevice();
	void CreateCommandQueueAndList();
	//���� Ÿ�� ��� ���� ���ٽ� �� ������
	void CreateRtvAndDsvDescriptorHeaps();
	//���� Ÿ�� ��� ���� ���ٽ� �� ����
	void CreateRenderTargetViews();
	void CreateDepthStencilView();
	//����ü�� ���� ��ȯ
	void ChangeSwapChainState();
	//��ü ���� �� ����
    void BuildObjects();
    void ReleaseObjects();
	//Ű���� �̺�Ʈ �� 
    void ProcessInput();
    void AnimateObjects();
    void FrameAdvance();
	//����ȭ �� ������ �ڿ� ����
	void WaitForGpuComplete();
	void MoveToNextFrame();
	//���콺 �� Ű���� �̺�Ʈ ����
	void OnProcessingMouseMessage(HWND hWnd, UINT nMessageID, WPARAM wParam, LPARAM lParam);
	void OnProcessingKeyboardMessage(HWND hWnd, UINT nMessageID, WPARAM wParam, LPARAM lParam);
	LRESULT CALLBACK OnProcessingWindowMessage(HWND hWnd, UINT nMessageID, WPARAM wParam, LPARAM lParam);
	
	//���� ���� ���� üũ
	//���� ����ȭ��-> 1
	//�ΰ��� ȭ�� -> 2
	//�޴� ȭ�� -> 3
	int							check = 0;
private:
	HINSTANCE					m_hInstance;
	HWND						m_hWnd; 

	int							m_nWndClientWidth;
	int							m_nWndClientHeight;
        
	IDXGIFactory4				*m_pdxgiFactory = NULL;
	IDXGISwapChain3				*m_pdxgiSwapChain = NULL;
	ID3D12Device				*m_pd3dDevice = NULL;

	bool						m_bMsaa4xEnable = false;
	UINT						m_nMsaa4xQualityLevels = 0;

	static const UINT			m_nSwapChainBuffers = 2;
	UINT						m_nSwapChainBufferIndex;

	ID3D12Resource				*m_ppd3dSwapChainBackBuffers[m_nSwapChainBuffers];
	ID3D12DescriptorHeap		*m_pd3dRtvDescriptorHeap = NULL;

	ID3D12Resource				*m_pd3dDepthStencilBuffer = NULL;
	ID3D12DescriptorHeap		*m_pd3dDsvDescriptorHeap = NULL;

	ID3D12CommandAllocator		*m_pd3dCommandAllocator = NULL;
	ID3D12CommandQueue			*m_pd3dCommandQueue = NULL;
	ID3D12GraphicsCommandList	*m_pd3dCommandList = NULL;

	ID3D12Fence					*m_pd3dFence = NULL;
	UINT64						m_nFenceValues[m_nSwapChainBuffers];
	HANDLE						m_hFenceEvent;

#if defined(_DEBUG)
	ID3D12Debug					*m_pd3dDebugController;
#endif

	CGameTimer					m_GameTimer;

	int							m_nScenes = 0;
	CScene						**m_ppScenes = NULL;

	int							m_nScene = 0;
	CScene						*m_pScene = NULL;

	CPlayer						*m_pPlayer = NULL;

	CCamera						*m_pCamera = NULL;

	POINT						m_ptOldCursorPos;

	_TCHAR						m_pszFrameRate[70];
};

