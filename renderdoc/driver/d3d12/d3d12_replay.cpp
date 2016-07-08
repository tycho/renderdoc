/******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2016 Baldur Karlsson
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

#include "d3d12_replay.h"
#include "d3d12_device.h"

D3D12Replay::D3D12Replay()
{
  m_pDevice = NULL;
  m_Proxy = false;
}

void D3D12Replay::Shutdown()
{
  for(size_t i = 0; i < m_ProxyResources.size(); i++)
    m_ProxyResources[i]->Release();
  m_ProxyResources.clear();

  m_pDevice->Release();
}

FetchTexture D3D12Replay::GetTexture(ResourceId id)
{
  FetchTexture tex;
  tex.ID = ResourceId();

  return tex;
}

ShaderReflection *D3D12Replay::GetShader(ResourceId shader, string entryPoint)
{
  return NULL;
}

void D3D12Replay::FreeTargetResource(ResourceId id)
{
  if(m_pDevice->GetResourceManager()->HasLiveResource(id))
  {
    ID3D12DeviceChild *resource = m_pDevice->GetResourceManager()->GetLiveResource(id);

    SAFE_RELEASE(resource);
  }
}

void D3D12Replay::FreeCustomShader(ResourceId id)
{
  if(m_pDevice->GetResourceManager()->HasLiveResource(id))
  {
    ID3D12DeviceChild *resource = m_pDevice->GetResourceManager()->GetLiveResource(id);

    SAFE_RELEASE(resource);
  }
}

FetchFrameRecord D3D12Replay::GetFrameRecord()
{
  return m_pDevice->GetFrameRecord();
}

vector<EventUsage> D3D12Replay::GetUsage(ResourceId id)
{
  return vector<EventUsage>();
}

vector<DebugMessage> D3D12Replay::GetDebugMessages()
{
  return vector<DebugMessage>();
}

APIProperties D3D12Replay::GetAPIProperties()
{
  APIProperties ret;

  ret.pipelineType = ePipelineState_D3D11;
  ret.degraded = false;

  return ret;
}

vector<ResourceId> D3D12Replay::GetBuffers()
{
  vector<ResourceId> ret;

  return ret;
}

FetchBuffer D3D12Replay::GetBuffer(ResourceId id)
{
  FetchBuffer ret;
  ret.ID = ResourceId();

  return ret;
}

vector<ResourceId> D3D12Replay::GetTextures()
{
  vector<ResourceId> ret;

  return ret;
}

D3D11PipelineState D3D12Replay::MakePipelineState()
{
  D3D11PipelineState ret;

  return ret;
}

void D3D12Replay::ReadLogInitialisation()
{
  m_pDevice->ReadLogInitialisation();
}

void D3D12Replay::SetContextFilter(ResourceId id, uint32_t firstDefEv, uint32_t lastDefEv)
{
  RDCERR("Should never hit SetContextFilter");
}

void D3D12Replay::ReplayLog(uint32_t endEventID, ReplayLogType replayType)
{
  m_pDevice->ReplayLog(0, endEventID, replayType);
}

vector<uint32_t> D3D12Replay::GetPassEvents(uint32_t eventID)
{
  vector<uint32_t> passEvents;

  return passEvents;
}

uint64_t D3D12Replay::MakeOutputWindow(void *w, bool depth)
{
  return m_pDevice->GetDebugManager()->MakeOutputWindow(w, depth);
}

void D3D12Replay::DestroyOutputWindow(uint64_t id)
{
  m_pDevice->GetDebugManager()->DestroyOutputWindow(id);
}

bool D3D12Replay::CheckResizeOutputWindow(uint64_t id)
{
  return m_pDevice->GetDebugManager()->CheckResizeOutputWindow(id);
}

void D3D12Replay::GetOutputWindowDimensions(uint64_t id, int32_t &w, int32_t &h)
{
  m_pDevice->GetDebugManager()->GetOutputWindowDimensions(id, w, h);
}

void D3D12Replay::ClearOutputWindowColour(uint64_t id, float col[4])
{
  m_pDevice->GetDebugManager()->ClearOutputWindowColour(id, col);
}

void D3D12Replay::ClearOutputWindowDepth(uint64_t id, float depth, uint8_t stencil)
{
  m_pDevice->GetDebugManager()->ClearOutputWindowDepth(id, depth, stencil);
}

void D3D12Replay::BindOutputWindow(uint64_t id, bool depth)
{
  m_pDevice->GetDebugManager()->BindOutputWindow(id, depth);
}

bool D3D12Replay::IsOutputWindowVisible(uint64_t id)
{
  return m_pDevice->GetDebugManager()->IsOutputWindowVisible(id);
}

void D3D12Replay::FlipOutputWindow(uint64_t id)
{
  m_pDevice->GetDebugManager()->FlipOutputWindow(id);
}

void D3D12Replay::InitPostVSBuffers(uint32_t eventID)
{
}

void D3D12Replay::InitPostVSBuffers(const vector<uint32_t> &passEvents)
{
}

ResourceId D3D12Replay::GetLiveID(ResourceId id)
{
  return m_pDevice->GetResourceManager()->GetLiveID(id);
}

bool D3D12Replay::GetMinMax(ResourceId texid, uint32_t sliceFace, uint32_t mip, uint32_t sample,
                            FormatComponentType typeHint, float *minval, float *maxval)
{
  *minval = 0.0f;
  *maxval = 1.0f;
  return false;
}

bool D3D12Replay::GetHistogram(ResourceId texid, uint32_t sliceFace, uint32_t mip, uint32_t sample,
                               FormatComponentType typeHint, float minval, float maxval,
                               bool channels[4], vector<uint32_t> &histogram)
{
  histogram.resize(256, 0);
  return false;
}

MeshFormat D3D12Replay::GetPostVSBuffers(uint32_t eventID, uint32_t instID, MeshDataStage stage)
{
  return MeshFormat();
}

void D3D12Replay::GetBufferData(ResourceId buff, uint64_t offset, uint64_t len, vector<byte> &retData)
{
}

byte *D3D12Replay::GetTextureData(ResourceId tex, uint32_t arrayIdx, uint32_t mip,
                                  FormatComponentType typeHint, bool resolve, bool forceRGBA8unorm,
                                  float blackPoint, float whitePoint, size_t &dataSize)
{
  dataSize = 0;
  return NULL;
}

void D3D12Replay::ReplaceResource(ResourceId from, ResourceId to)
{
  m_pDevice->GetResourceManager()->ReplaceResource(from, to);
}

void D3D12Replay::RemoveReplacement(ResourceId id)
{
  m_pDevice->GetResourceManager()->RemoveReplacement(id);
}

vector<uint32_t> D3D12Replay::EnumerateCounters()
{
  return vector<uint32_t>();
}

void D3D12Replay::DescribeCounter(uint32_t counterID, CounterDescription &desc)
{
  desc = CounterDescription();
}

vector<CounterResult> D3D12Replay::FetchCounters(const vector<uint32_t> &counters)
{
  return vector<CounterResult>();
}

void D3D12Replay::RenderMesh(uint32_t eventID, const vector<MeshFormat> &secondaryDraws,
                             const MeshDisplay &cfg)
{
}

void D3D12Replay::BuildTargetShader(string source, string entry, const uint32_t compileFlags,
                                    ShaderStageType type, ResourceId *id, string *errors)
{
}

void D3D12Replay::BuildCustomShader(string source, string entry, const uint32_t compileFlags,
                                    ShaderStageType type, ResourceId *id, string *errors)
{
}

bool D3D12Replay::RenderTexture(TextureDisplay cfg)
{
  return false;
}

void D3D12Replay::RenderCheckerboard(Vec3f light, Vec3f dark)
{
}

void D3D12Replay::RenderHighlightBox(float w, float h, float scale)
{
}

void D3D12Replay::FillCBufferVariables(ResourceId shader, string entryPoint, uint32_t cbufSlot,
                                       vector<ShaderVariable> &outvars, const vector<byte> &data)
{
  return;
}

vector<PixelModification> D3D12Replay::PixelHistory(vector<EventUsage> events, ResourceId target,
                                                    uint32_t x, uint32_t y, uint32_t slice,
                                                    uint32_t mip, uint32_t sampleIdx,
                                                    FormatComponentType typeHint)
{
  return vector<PixelModification>();
}

ShaderDebugTrace D3D12Replay::DebugVertex(uint32_t eventID, uint32_t vertid, uint32_t instid,
                                          uint32_t idx, uint32_t instOffset, uint32_t vertOffset)
{
  return ShaderDebugTrace();
}

ShaderDebugTrace D3D12Replay::DebugPixel(uint32_t eventID, uint32_t x, uint32_t y, uint32_t sample,
                                         uint32_t primitive)
{
  return ShaderDebugTrace();
}

ShaderDebugTrace D3D12Replay::DebugThread(uint32_t eventID, uint32_t groupid[3], uint32_t threadid[3])
{
  return ShaderDebugTrace();
}

uint32_t D3D12Replay::PickVertex(uint32_t eventID, const MeshDisplay &cfg, uint32_t x, uint32_t y)
{
  return ~0U;
}

void D3D12Replay::PickPixel(ResourceId texture, uint32_t x, uint32_t y, uint32_t sliceFace,
                            uint32_t mip, uint32_t sample, FormatComponentType typeHint,
                            float pixel[4])
{
}

ResourceId D3D12Replay::RenderOverlay(ResourceId texid, FormatComponentType typeHint,
                                      TextureDisplayOverlay overlay, uint32_t eventID,
                                      const vector<uint32_t> &passEvents)
{
  return ResourceId();
}

ResourceId D3D12Replay::ApplyCustomShader(ResourceId shader, ResourceId texid, uint32_t mip,
                                          FormatComponentType typeHint)
{
  return ResourceId();
}

bool D3D12Replay::IsRenderOutput(ResourceId id)
{
  return false;
}

void D3D12Replay::InitCallstackResolver()
{
  m_pDevice->GetSerialiser()->InitCallstackResolver();
}

bool D3D12Replay::HasCallstacks()
{
  return m_pDevice->GetSerialiser()->HasCallstacks();
}

Callstack::StackResolver *D3D12Replay::GetCallstackResolver()
{
  return m_pDevice->GetSerialiser()->GetCallstackResolver();
}

ResourceId D3D12Replay::CreateProxyTexture(const FetchTexture &templateTex)
{
  return ResourceId();
}

void D3D12Replay::SetProxyTextureData(ResourceId texid, uint32_t arrayIdx, uint32_t mip, byte *data,
                                      size_t dataSize)
{
}

ResourceId D3D12Replay::CreateProxyBuffer(const FetchBuffer &templateBuf)
{
  return ResourceId();
}

void D3D12Replay::SetProxyBufferData(ResourceId bufid, byte *data, size_t dataSize)
{
}

extern "C" __declspec(dllexport) HRESULT
    __cdecl RENDERDOC_CreateWrappedD3D12Device(IUnknown *pAdapter,
                                               D3D_FEATURE_LEVEL MinimumFeatureLevel, REFIID riid,
                                               void **ppDevice);

ReplayCreateStatus D3D12_CreateReplayDevice(const char *logfile, IReplayDriver **driver)
{
  RDCDEBUG("Creating a D3D12 replay device");

  HMODULE lib = NULL;
  lib = LoadLibraryA("d3d12.dll");
  if(lib == NULL)
  {
    RDCERR("Failed to load d3d12.dll");
    return eReplayCreate_APIInitFailed;
  }

  lib = LoadLibraryA("dxgi.dll");
  if(lib == NULL)
  {
    RDCERR("Failed to load dxgi.dll");
    return eReplayCreate_APIInitFailed;
  }

  if(GetD3DCompiler() == NULL)
  {
    RDCERR("Failed to load d3dcompiler_??.dll");
    return eReplayCreate_APIInitFailed;
  }

  D3D12InitParams initParams;
  RDCDriver driverFileType = RDC_D3D12;
  string driverName = "D3D12";
  if(logfile)
  {
    auto status = RenderDoc::Inst().FillInitParams(logfile, driverFileType, driverName,
                                                   (RDCInitParams *)&initParams);
    if(status != eReplayCreate_Success)
      return status;
  }

  // initParams.SerialiseVersion is guaranteed to be valid/supported since otherwise the
  // FillInitParams (which calls D3D12InitParams::Serialise) would have failed above, so no need to
  // check it here.

  if(initParams.MinimumFeatureLevel < D3D_FEATURE_LEVEL_11_0)
    initParams.MinimumFeatureLevel = D3D_FEATURE_LEVEL_11_0;

  ID3D12Device *dev = NULL;
  HRESULT hr = RENDERDOC_CreateWrappedD3D12Device(NULL, initParams.MinimumFeatureLevel,
                                                  __uuidof(ID3D12Device), (void **)&dev);

  if(FAILED(hr))
  {
    RDCERR("Couldn't create a d3d12 device :(.");

    return eReplayCreate_APIHardwareUnsupported;
  }

  WrappedID3D12Device *wrappedDev = (WrappedID3D12Device *)dev;
  if(logfile)
    wrappedDev->SetLogFile(logfile);
  wrappedDev->SetLogVersion(initParams.SerialiseVersion);

  RDCLOG("Created device.");
  D3D12Replay *replay = wrappedDev->GetReplay();

  replay->SetProxy(logfile == NULL);

  *driver = (IReplayDriver *)replay;
  return eReplayCreate_Success;
}

static DriverRegistration D3D12DriverRegistration(RDC_D3D12, "D3D12", &D3D12_CreateReplayDevice);
