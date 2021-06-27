using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Automaton : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;
    [SerializeField] private int textureWidth = 1024;
    [SerializeField] private int textureHeight = 1024;
    [SerializeField] private Renderer targetRenderer;
    [SerializeField] private int colorNum = 20;
    [SerializeField] private float radius = 16.0f;
    [SerializeField] private float fps = 10.0f;
    private int patternWidth = 512;
    private int patternHeight = 512;

    private int kernelIdNextState;
    private int kernelIdDrawTexture;
    private ComputeBuffer stateBuffer;
    private ComputeBuffer nextStateBuffer;
    private ComputeBuffer colorBuffer;
    private uint[] stateArray1;
    private uint[] stateArray2;
    private RenderTexture targetTexture;
    private int frame = 0;

    // Start is called before the first frame update
    void Start()
    {
        kernelIdNextState = computeShader.FindKernel("CalcNextState");
        kernelIdDrawTexture = computeShader.FindKernel("DrawTexture");

        Debug.Log($"{patternWidth} x {patternHeight}");

        stateArray1 = new uint[patternWidth * patternHeight];
        stateArray2 = new uint[patternWidth * patternHeight];
        stateBuffer = new ComputeBuffer(patternWidth * patternHeight, sizeof(uint), ComputeBufferType.Raw);
        nextStateBuffer = new ComputeBuffer(patternWidth * patternHeight, sizeof(uint), ComputeBufferType.Raw);

        targetTexture = new RenderTexture(textureWidth, textureHeight, 0, RenderTextureFormat.ARGB32);
        targetTexture.enableRandomWrite = true;
        targetTexture.filterMode = FilterMode.Point;
        targetTexture.Create();

        var unitx = 1.5f * radius;
        var unity = 1.73205080757f * radius;
        var normalLen = 0.86602540378f * radius;
        int cx = (int)Mathf.Floor(textureWidth / 2f / unitx);
        int cy = (int)Mathf.Floor((textureHeight / 2f - normalLen * (float)cx) / unity);
        var center = cy * patternWidth + cx;
        stateArray1[center] = 1;

        var colorArray = new float[3 * colorNum];
        for (var i = 0; i < colorNum; i++)
        {
            var color = Color.HSVToRGB((float)i / (float)colorNum, (float)i / (float)colorNum, 1f);
            colorArray[3 * i + 0] = color.r;
            colorArray[3 * i + 1] = color.g;
            colorArray[3 * i + 2] = color.b;
        }
        colorArray[0] = 0;
        colorArray[1] = 0;
        colorArray[2] = 0;
        colorBuffer = new ComputeBuffer(3 * colorNum, sizeof(float), ComputeBufferType.Raw);
        colorBuffer.SetData(colorArray);

        computeShader.SetInt("_Width", patternWidth);
        computeShader.SetInt("_Height", patternHeight);
        computeShader.SetFloat("_R", radius);
        computeShader.SetBuffer(kernelIdNextState, "_States", stateBuffer);
        computeShader.SetBuffer(kernelIdNextState, "_NextStates", nextStateBuffer);
        computeShader.SetTexture(kernelIdDrawTexture, "_Texture", targetTexture);
        computeShader.SetBuffer(kernelIdDrawTexture, "_States", nextStateBuffer);
        computeShader.SetBuffer(kernelIdDrawTexture, "_Colors", colorBuffer);

        targetRenderer.material.mainTexture = targetTexture;

        StartCoroutine(FpsLoop());
    }

    IEnumerator FpsLoop()
    {
        while (true)
        {
            yield return new WaitForSeconds(0.999f / fps);
            LocalUpdate();
        }
    }

    // Update is called once per frame
    void LocalUpdate()
    {
        if (frame % 2 == 0)
        {
            stateBuffer.SetData(stateArray1);
            computeShader.Dispatch(kernelIdNextState, patternWidth / 8, patternHeight / 8, 1);
            nextStateBuffer.GetData(stateArray2);
            // Debug.Log(string.Join(",", stateArray2));
        }
        else
        {
            stateBuffer.SetData(stateArray2);
            computeShader.Dispatch(kernelIdNextState, patternWidth / 8, patternHeight / 8, 1);
            nextStateBuffer.GetData(stateArray1);
            // Debug.Log(string.Join(",", stateArray1));
        }
        computeShader.Dispatch(kernelIdDrawTexture, textureWidth / 8, textureHeight / 8, 1);

        frame++;
    }

    void OnDestroy()
    {
        if (stateBuffer != null) stateBuffer.Dispose();
        if (nextStateBuffer != null) nextStateBuffer.Dispose();
    }
}
